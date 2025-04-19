#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BUFFER_SIZE 256
#define MIN_KEY_LENGTH 8

#ifdef __APPLE__
#include <TargetConditionals.h>
#if TARGET_OS_IOS
#define PLATFORM_IOS
#elif TARGET_OS_MAC
#define PLATFORM_MAC
#endif
#endif

// XOR şifreleme fonksiyonu
int xor_encrypt_decrypt(const char *input, const char *key, char *output, size_t output_size) {
    if (!input || !key || !output || output_size == 0) {
        return -1;
    }

    size_t len = strlen(input);
    size_t key_len = strlen(key);

    if (key_len < MIN_KEY_LENGTH) {
        return -2;  // Anahtar çok kısa
    }

    if (len >= output_size) {
        return -3;  // Buffer yetersiz
    }

    for (size_t i = 0; i < len; i++) {
        output[i] = input[i] ^ key[i % key_len];
    }
    output[len] = '\0';
    return 0;
}

// Güvenli girdi okuma
int secure_input(char *buffer, size_t size) {
    if (!buffer || size == 0) {
        return -1;
    }

    if (fgets(buffer, size, stdin) == NULL) {
        return -2;
    }

    size_t len = strlen(buffer);
    if (len > 0 && buffer[len-1] == '\n') {
        buffer[len-1] = '\0';
    }

    return 0;
}

void print_platform_info(void) {
    #ifdef PLATFORM_IOS
        printf("Platform: iOS\n");
    #elif defined(PLATFORM_MAC)
        printf("Platform: macOS\n");
    #elif defined(__linux__)
        printf("Platform: Linux\n");
    #elif defined(_WIN32)
        printf("Platform: Windows\n");
    #else
        printf("Platform: Diğer\n");
    #endif
}

int main() {
    char input[BUFFER_SIZE] = {0};
    char key[BUFFER_SIZE] = {0};
    char encrypted[BUFFER_SIZE] = {0};
    char decrypted[BUFFER_SIZE] = {0};
    int result;

    printf("Metin girin: ");
    if (secure_input(input, sizeof(input)) != 0) {
        fprintf(stderr, "Girdi okuma hatası!\n");
        return EXIT_FAILURE;
    }

    printf("Şifreleme anahtarı girin (en az %d karakter): ", MIN_KEY_LENGTH);
    if (secure_input(key, sizeof(key)) != 0) {
        fprintf(stderr, "Anahtar okuma hatası!\n");
        return EXIT_FAILURE;
    }

    result = xor_encrypt_decrypt(input, key, encrypted, sizeof(encrypted));
    if (result != 0) {
        fprintf(stderr, "Şifreleme hatası (kod: %d)!\n", result);
        return EXIT_FAILURE;
    }
    printf("Şifrelenmiş metin: %s\n", encrypted);

    result = xor_encrypt_decrypt(encrypted, key, decrypted, sizeof(decrypted));
    if (result != 0) {
        fprintf(stderr, "Şifre çözme hatası (kod: %d)!\n", result);
        return EXIT_FAILURE;
    }
    printf("Çözülmüş metin: %s\n", decrypted);

    print_platform_info();
    return EXIT_SUCCESS;
}