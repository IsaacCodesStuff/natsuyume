#ifndef LRCPARSER_H
#define LRCPARSER_H

#include <string>
#include <vector>
#include <cstdint>

struct LrcLine {
    int64_t     timestamp; // milliseconds
    std::string text;
};

class LrcParser {
public:
    // Parses raw LRC text into a sorted list of timed lines.
    // Lines with no timestamp (metadata tags like [ar:], [ti:]) are skipped.
    static std::vector<LrcLine> parse(const std::string &lrc);

    // Returns true if the string looks like LRC (has at least one [mm:ss] tag).
    static bool isLrc(const std::string &text);
};

#endif // LRCPARSER_H