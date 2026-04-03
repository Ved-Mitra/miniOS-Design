with open("kernel/pipe.c", "r") as f:
    text = f.read()

text = text.replace("mem_alloc(MEM_PIPE)", "kalloc()")
text = text.replace("mem_free((char*)pi)", "kfree((char*)pi)")

with open("kernel/pipe.c", "w") as f:
    f.write(text)

with open("kernel/main.c", "r") as f:
    text = f.read()

text = text.replace("meminit();", "// meminit();")

with open("kernel/main.c", "w") as f:
    f.write(text)
