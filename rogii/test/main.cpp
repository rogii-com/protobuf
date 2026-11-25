#include "probe.pb.h"

#include <google/protobuf/stubs/common.h>

#include <cstdio>
#include <string>

namespace
{
int parsePackedValues()
{
    probe::Values source;
    for(int i = 0; i < 100; ++i)
    {
        source.add_values(i);
    }

    std::string bytes;
    if(!source.SerializeToString(&bytes))
    {
        std::puts("serialize failed");
        return 1;
    }

    // Clear() runs in this binary and, under ASan, poisons the spare capacity;
    // the packed parse inside libprotobuf then copies into that capacity, which
    // ASan reports unless libprotobuf is instrumented as well.
    probe::Values target;
    for(int i = 0; i < 300; ++i)
    {
        target.add_values(-1);
    }
    target.Clear();

    if(!target.ParseFromString(bytes) || target.values_size() != 100 || target.values(99) != 99)
    {
        std::puts("parse mismatch");
        return 1;
    }

    std::puts("parsed packed values");
    return 0;
}
}

int main()
{
    const int result = parsePackedValues();
    google::protobuf::ShutdownProtobufLibrary();
    return result;
}
