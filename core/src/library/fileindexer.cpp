#include "fileindexer.h"
#include "metadata.h"
#include <filesystem>
#include <algorithm>
#include <chrono>
#include <unicode/unorm2.h>
#include <unicode/ustring.h>

namespace fs = std::filesystem;

const std::vector<std::string> FileIndexer::s_supportedExtensions = {
    "mp3", "flac", "wav", "ogg", "opus", "m4a"
};

static std::string toLower(std::string s)
{
    std::transform(s.begin(), s.end(), s.begin(),
                   [](unsigned char c){ return std::tolower(c); });
    return s;
}

static std::string extensionOf(const fs::path &p)
{
    std::string ext = p.extension().string();
    if (!ext.empty() && ext.front() == '.')
        ext = ext.substr(1);
    return toLower(ext);
}

static bool isSupportedExtension(const std::string &ext)
{
    const auto &exts = FileIndexer::s_supportedExtensions;
    return std::find(exts.begin(), exts.end(), ext) != exts.end();
}

static std::string nfcNormalize(const std::string &s)
{
    if (s.empty()) return s;
    UErrorCode err = U_ZERO_ERROR;
    const UNormalizer2 *nfc = unorm2_getNFCInstance(&err);
    if (U_FAILURE(err)) return s;

    int32_t u16len = 0;
    u_strFromUTF8(nullptr, 0, &u16len, s.c_str(), -1, &err);
    err = U_ZERO_ERROR;
    std::vector<UChar> u16(u16len + 1);
    u_strFromUTF8(u16.data(), u16len + 1, &u16len, s.c_str(), -1, &err);
    if (U_FAILURE(err)) return s;

    std::vector<UChar> norm(u16len * 2 + 1);
    int32_t normLen = unorm2_normalize(nfc, u16.data(), u16len,
                                       norm.data(), norm.size(), &err);
    if (U_FAILURE(err)) return s;

    int32_t u8len = 0;
    u_strToUTF8(nullptr, 0, &u8len, norm.data(), normLen, &err);
    err = U_ZERO_ERROR;
    std::string result(u8len, '\0');
    u_strToUTF8(result.data(), u8len + 1, &u8len, norm.data(), normLen, &err);
    if (U_FAILURE(err)) return s;

    return result;
}

FileIndexer::FileIndexer() = default;

FileIndexer::~FileIndexer()
{
    cancel();
    if (m_thread.joinable())
        m_thread.join();
}

bool FileIndexer::isScanning() const
{
    return m_scanning.load();
}

void FileIndexer::setKnownPaths(const std::unordered_map<std::string, int64_t> &paths)
{
    m_knownPathsSnapshot = paths;
}

void FileIndexer::scanFolder(const std::string &folderPath)
{
    if (m_scanning.load()) return;

    if (m_thread.joinable())
        m_thread.join();

    m_cancelled.store(false);
    m_scanning.store(true);
    m_knownPaths = m_knownPathsSnapshot;

    if (m_onScanningChanged) m_onScanningChanged(true);

    m_thread = std::thread([this, folderPath]() {
        doScan(folderPath);
        m_scanning.store(false);
        if (m_onScanningChanged) m_onScanningChanged(false);
    });
}

void FileIndexer::cancel()
{
    if (!m_scanning.load()) return;
    m_cancelled.store(true);
    if (m_thread.joinable())
        m_thread.join();
    m_scanning.store(false);
}

void FileIndexer::doScan(const std::string &folderPath)
{
    try {
        fs::path root(folderPath);
        if (!fs::exists(root) || !fs::is_directory(root)) {
            if (m_onScanFinished) m_onScanFinished();
            return;
        }

        // Count supported files first
        int total = 0;
        std::error_code ec;
        for (const auto &entry : fs::recursive_directory_iterator(
                root, fs::directory_options::skip_permission_denied, ec)) {
            if (entry.is_regular_file() &&
                isSupportedExtension(extensionOf(entry.path())))
                total++;
        }

        if (m_onScanStarted) m_onScanStarted(total);

        int scanned = 0;
        std::vector<Track> batch;
        batch.reserve(10);
        const int batchSize = 10;

        for (const auto &entry : fs::recursive_directory_iterator(
                root, fs::directory_options::skip_permission_denied, ec)) {
            if (m_cancelled.load()) {
                if (!batch.empty() && m_onTracksFound)
                    m_onTracksFound(batch);
                if (m_onScanCancelled) m_onScanCancelled();
                return;
            }

            if (!entry.is_regular_file()) continue;
            if (!isSupportedExtension(extensionOf(entry.path()))) continue;

            // NFC-normalize the path for consistent DB keying
            const std::string path = nfcNormalize(entry.path().string());

            // Get disk modification time
            int64_t diskMtime = 0;
            std::error_code mec;
            auto ftime = fs::last_write_time(entry.path(), mec);
            if (!mec) {
                diskMtime = std::chrono::duration_cast<std::chrono::seconds>(
                    ftime.time_since_epoch()).count();
            }

            auto it = m_knownPaths.find(path);
            bool isNew      = (it == m_knownPaths.end());
            bool isModified = !isNew && (it->second < diskMtime);

            if (isNew || isModified) {
                Track track = Metadata::read(path, false);
                track.lastModified = diskMtime;
                m_knownPaths[path] = diskMtime;

                batch.push_back(std::move(track));

                if ((int)batch.size() >= batchSize) {
                    if (m_onTracksFound) m_onTracksFound(batch);
                    batch.clear();
                }
            }

            if (m_onScanProgress)
                m_onScanProgress(++scanned, total,
                                 entry.path().filename().string());
        }

        if (!batch.empty() && m_onTracksFound)
            m_onTracksFound(batch);

        if (m_onScanFinished) m_onScanFinished();

    } catch (...) {
        if (m_onScanFinished) m_onScanFinished();
    }
}