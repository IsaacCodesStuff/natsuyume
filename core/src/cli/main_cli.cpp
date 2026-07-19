#include <QCoreApplication>
#include <QTimer>
#include <QSocketNotifier>
#include <iostream>
#include <string>
#include <vector>
#include <filesystem>
#include "natsuyumecore.h"

using namespace Natsuyume;
namespace fs = std::filesystem;

static bool isAudioFile(const fs::path &p)
{
    const std::string ext = p.extension().string();
    return ext == ".flac" || ext == ".mp3" || ext == ".ogg"
           || ext == ".opus" || ext == ".m4a" || ext == ".wav"
           || ext == ".aac"  || ext == ".wv"  || ext == ".ape";
}

static void printHelp()
{
    std::cout << "\nCommands:\n"
              << "  play      Resume playback\n"
              << "  pause     Pause playback\n"
              << "  next      Next track\n"
              << "  prev      Previous track\n"
              << "  quit      Exit\n"
              << "  help      Show this list\n\n";
}

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    if (argc < 2) {
        std::cerr << "Usage: natsuyume-cli <folder>\n";
        return 1;
    }

    const std::string folder = argv[1];

    // --- Scan folder with std::filesystem, no DB ---
    std::vector<std::string> paths;
    try {
        for (const auto &entry : fs::recursive_directory_iterator(
                 folder, fs::directory_options::skip_permission_denied)) {
            if (entry.is_regular_file() && isAudioFile(entry.path()))
                paths.push_back(entry.path().string());
        }
    } catch (const std::exception &e) {
        std::cerr << "Scan error: " << e.what() << "\n";
        return 1;
    }

    std::sort(paths.begin(), paths.end());

    if (paths.empty()) {
        std::cout << "No audio files found in: " << folder << "\n";
        return 0;
    }

    std::cout << "\nFound " << paths.size() << " track(s):\n\n";
    for (size_t i = 0; i < paths.size(); ++i) {
        std::string name = fs::path(paths[i]).stem().string();
        std::cout << "  [" << (i + 1) << "] " << name << "\n";
    }
    std::cout << "\nEnter a number to play, or 'help' for commands.\n> "
              << std::flush;

    // --- Core setup ---
    NatsuyumeCore core;

    core.callbacks.onPlaybackStateChanged = [](bool isPlaying) {
        std::cout << (isPlaying ? "\n[playing]" : "\n[paused]")
        << "\n> " << std::flush;
    };

    core.callbacks.onTrackChanged = [](const CoreTrack &track) {
        std::string name = track.title.empty()
        ? fs::path(track.path).stem().string()
        : track.title;
        std::string artist = track.artist.empty() ? "" : track.artist + " — ";
        std::cout << "\nNow playing: " << artist << name
                  << "\n> " << std::flush;
    };

    core.init();

    // --- Stdin reader ---
    QSocketNotifier notifier(fileno(stdin), QSocketNotifier::Read);
    QObject::connect(&notifier, &QSocketNotifier::activated, [&]() {
        std::string line;
        if (!std::getline(std::cin, line)) {
            QCoreApplication::quit();
            return;
        }

        while (!line.empty() && (line.back() == '\r' || line.back() == ' '))
            line.pop_back();

        if (line.empty()) {
            std::cout << "> " << std::flush;
            return;
        }

        // Numeric: pick a track
        bool isNumber = !line.empty();
        for (char c : line) if (!std::isdigit(c)) { isNumber = false; break; }

        if (isNumber) {
            int index = std::stoi(line) - 1;
            if (index < 0 || index >= static_cast<int>(paths.size())) {
                std::cout << "Invalid number.\n> " << std::flush;
                return;
            }
            // Load all tracks into the queue, jump to the selected one
            core.openFilesInNewQueue(paths);
            core.jumpToTrack(index);
            return;
        }

        // Text commands
        if      (line == "play")           core.play();
        else if (line == "pause")          core.pause();
        else if (line == "next")           core.playNext();
        else if (line == "prev") {
            if (core.position() > 10000)  // position is in milliseconds
                core.seekTo(0);
            else
                core.playPrevious();
        }
        else if (line == "help")         { printHelp(); std::cout << "> " << std::flush; }
        else if (line == "quit" || line == "q") {
            core.shutdown();
            QCoreApplication::quit();
            return;
        } else {
            std::cout << "Unknown command. Type 'help' for commands.\n> " << std::flush;
        }
    });

    return app.exec();
}