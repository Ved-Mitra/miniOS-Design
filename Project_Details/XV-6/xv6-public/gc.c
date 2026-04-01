// Garbage collector

#include "types.h"
#include "defs.h"
#include "param.h"
#include "fs.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "file.h"

void garbage_collect(void){
    struct memfile *mf;
    acquire(&mftable.lock);
    for(int i=0;i<NMEMFILE;i++){
        mf = &mftable.memfiles[i];
        if(mf->is_marked_deleted==1 && mf->ref_count==0){
            // Free the memory associated with this memfile
            if(mf->data!=0){
                kfree(mf->data);
                mf->data = 0;
            }
            // Reset memfile fields
            mf->ref_count = 0;
            mf->size = 0;
            mf->is_marked_deleted = 0;
            cprintf("GC: Collected memfile [%d] and freed associated memory blocks\n", i);
        }
    }
    release(&mftable.lock);
}