#include "lrcparser.h"
#include <QRegularExpression>
#include <algorithm>

static const QRegularExpression kTimestamp(
    R"(\[(\d{1,3}):(\d{2})[\.\:](\d{1,3})\])"
    );

static const QRegularExpression kMetaTag(
    R"(\[[a-z]+:.*\])"
    );

bool LrcParser::isLrc(const QString &text)
{
    return kTimestamp.match(text).hasMatch();
}

QList<LrcLine> LrcParser::parse(const QString &lrc)
{
    QList<LrcLine> result;

    for (const QString &rawLine : lrc.split('\n')) {
        QString line = rawLine.trimmed();
        if (line.isEmpty()) continue;

        // Collect all timestamps on this line (a line can have multiple)
        QList<qint64> timestamps;
        auto it = kTimestamp.globalMatch(line);
        while (it.hasNext()) {
            auto m = it.next();
            int  mins  = m.captured(1).toInt();
            int  secs  = m.captured(2).toInt();
            // Third group may be centiseconds (2 digits) or milliseconds (3 digits)
            QString csStr = m.captured(3);
            int ms = csStr.toInt();
            if (csStr.length() <= 2)
                ms *= 10; // centiseconds → milliseconds
            timestamps << (qint64(mins) * 60000 + qint64(secs) * 1000 + ms);
        }

        if (timestamps.isEmpty()) continue;

        // Strip all timestamp tags to get the lyric text
        QString text = line;
        text.remove(kTimestamp);
        text.remove(kMetaTag);
        text = text.trimmed();

        // One LRC line can carry multiple timestamps (repeated chorus etc.)
        for (qint64 ts : timestamps)
            result << LrcLine{ ts, text };
    }

    std::sort(result.begin(), result.end(),
              [](const LrcLine &a, const LrcLine &b){ return a.timestamp < b.timestamp; });

    return result;
}