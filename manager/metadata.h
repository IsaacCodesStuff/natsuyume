#ifndef METADATA_H
#define METADATA_H

#include "track.h"

class Metadata
{
public:
    static Track read(const QString &path);
};

#endif // METADATA_H