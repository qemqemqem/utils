import openai
import os
import time
import requests
from io import BytesIO
import threading

openai.api_key = os.environ["OPENAI_API_KEY"]


def generate_image_and_return_url(prompt):
    response = openai.Image.create(
        prompt=prompt,
        n=1,
        size="256x256"
    )
    image_url = response['data'][0]['url']
    return image_url
    

def generate_image_and_save_to_file(prompt, file_name):
    image_url = generate_image_and_return_url(prompt)
    image_data = requests.get(image_url).content
    with open(file_name, 'wb') as handler:
        handler.write(image_data)


if __name__ == "__main__":
    image = "Alas, a canine of noble birth embarked on a perilous journey, and in his travels, he chanced upon a fair maiden of the same breed, and thus, they fell in love and lived happily ever after"
    image_url = generate_image_and_return_url(image)
    print(image_url)
