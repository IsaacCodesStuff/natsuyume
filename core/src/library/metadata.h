#ifndef METADATA_H
#define METADATA_H

#include "track.h"
#include <string>

class Metadata
{
public:
    static Track read(const std::string &path, bool includeCoverArt = true);
};

#endif // METADATA_H