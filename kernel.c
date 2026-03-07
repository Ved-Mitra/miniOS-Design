void kernel_main() {
    // Pointer to the start of VGA text buffer
    char* video_memory = (char*) 0xB8000;

    // "Hello World" in VGA: Character, then Attribute (Color)
    // 0x07 is Light Grey on Black
    const char* str = "Welcome";
    
    for(int i = 0; str[i] != '\0'; i++) {
        video_memory[i * 2] = str[i];     // The character
        video_memory[i * 2 + 1] = 0x07;   // The color
    }
}