with open("kernel/pipe.c", "r") as f:
    text = f.read()

text = text.replace("mem_free(pi);", "kfree((void*)pi);")

with open("kernel/pipe.c", "w") as f:
    f.write(text)
