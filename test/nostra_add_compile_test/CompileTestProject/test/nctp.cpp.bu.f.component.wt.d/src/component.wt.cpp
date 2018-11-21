
#include "nostra/testproject/component.h"

extern int test2();

/* The compile error is in source.cpp */

int main()
{
    test2();
    test(); /* from nostra/testproject/component.h */

    return 0;
}