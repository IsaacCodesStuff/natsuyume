#ifndef LRCPARSER_H
#define LRCPARSER_H

#include <QString>
#include <QList>

struct LrcLine {
    qint64  timestamp; // milliseconds
    QString text;
};

class LrcParser {
public:
    // Parses raw LRC text into a sorted list of timed lines.
    // Lines with no timestamp (metadata tags like [ar:], [ti:]) are skipped.
    static QList<LrcLine> parse(const QString &lrc);

    // Returns true if the string looks like LRC (has at least one [mm:ss] tag).
    static bool isLrc(const QString &text);
};

#endif // LRCPARSER_H