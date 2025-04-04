from machine import Pin
from time import sleep

# LED'i bağladığınız GPIO pin numarasını belirtin
led_pin = 2  # Örneğin, GPIO 2

# LED pinini çıkış olarak ayarla
led = Pin(led_pin, Pin.OUT)

def led_yak_sondur():
    while True:
        led.on()
        print("LED yandı")
        sleep(1)  # 1 saniye bekle
        led.off()
        print("LED söndü")
        sleep(1)  # 1 saniye bekle

if __name__ == "__main__":
    led_yak_sondur()