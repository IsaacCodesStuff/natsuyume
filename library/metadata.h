#ifndef METADATA_H
#define METADATA_H

#include "track.h"
#include <QString>

class Metadata
{
public:
    static Track read(const QString &path, bool includeCoverArt = true);
};

#endif // METADATA_H