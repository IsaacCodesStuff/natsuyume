#include "lrcparser.h"
#include <regex>
#include <sstream>
#include <algorithm>

static const std::regex kTimestamp(
    R"(\[(\d{1,3}):(\d{2})[\.\:](\d{1,3})\])"
);

static const std::regex kMetaTag(
    R"(\[[a-z]+:.*\])"
);

bool LrcParser::isLrc(const std::string &text)
{
    return std::regex_search(text, kTimestamp);
}

std::vector<LrcLine> LrcParser::parse(const std::string &lrc)
{
    std::vector<LrcLine> result;

    std::istringstream stream(lrc);
    std::string rawLine;

    while (std::getline(stream, rawLine)) {
        // Trim whitespace
        auto start = rawLine.find_first_not_of(" \t\r");
        auto end   = rawLine.find_last_not_of(" \t\r");
        if (start == std::string::npos) continue;
        std::string line = rawLine.substr(start, end - start + 1);
        if (line.empty()) continue;

        // Collect all timestamps on this line
        std::vector<int64_t> timestamps;
        auto it  = std::sregex_iterator(line.begin(), line.end(), kTimestamp);
        auto eof = std::sregex_iterator();
        for (; it != eof; ++it) {
            const auto &m  = *it;
            int mins       = std::stoi(m[1].str());
            int secs       = std::stoi(m[2].str());
            std::string csStr = m[3].str();
            int ms         = std::stoi(csStr);
            if (csStr.length() <= 2)
                ms *= 10; // centiseconds → milliseconds
            timestamps.push_back(int64_t(mins) * 60000 + int64_t(secs) * 1000 + ms);
        }

        if (timestamps.empty()) continue;

        // Strip all timestamp and meta tags to get the lyric text
        std::string text = std::regex_replace(line, kTimestamp, "");
        text = std::regex_replace(text, kMetaTag, "");

        // Trim the result
        auto ts = text.find_first_not_of(" \t");
        auto te = text.find_last_not_of(" \t");
        if (ts != std::string::npos)
            text = text.substr(ts, te - ts + 1);
        else
            text = "";

        for (int64_t ts : timestamps)
            result.push_back({ ts, text });
    }

    std::sort(result.begin(), result.end(),
              [](const LrcLine &a, const LrcLine &b){ return a.timestamp < b.timestamp; });

    return result;
}