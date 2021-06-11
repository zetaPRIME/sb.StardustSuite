#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Paktify: fixes .pak file order to ensure .patch files are listed last
# requires: https://github.com/blixt/py-starbound/

import mmap
import optparse
import os
import sys

import starbound
from starbound import sbon

def main():
    p = optparse.OptionParser('Usage: %prog <package path>')
    options, arguments = p.parse_args()
    if len(arguments) < 1:
        p.error('Must specify .pak path.')
    package_path = arguments[0]
    
    with open(package_path, 'rb+') as fh:
        mm = mmap.mmap(fh.fileno(), 0, access=mmap.ACCESS_WRITE)
        pak = starbound.SBAsset6(mm)
        
        pak.read_header()
        
        ent = { } # file entries
        mm.seek(pak.index_offset)
        for i in range(pak.file_count):
            start = mm.tell()
            path = sbon.read_string(mm)
            mm.read(16) # seek past offset and length
            end = mm.tell()
            length = end - start
            mm.seek(start)
            ent[path] = mm.read(length) # store full entry bytes
        
        mm.seek(pak.index_offset) # return to start of file index
        p_ent = { }
        for k, v in ent.items():
            if k.lower().endswith(".patch"):
                p_ent[k] = v
            else:
                #print(k)
                mm.write(v) # write entry
        
        for k, v in p_ent.items():
            #print(k)
            mm.write(v)
        
        mm.flush()
    #

if __name__ == '__main__':
    main()
