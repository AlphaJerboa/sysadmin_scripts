#!/usr/bin/python3

'''
  Programname :
  Author :
  Version :
  Description
'''

import requests
from bs4 import BeautifulSoup
import sys

def main():


    try:
        url = str(sys.argv[1])
    except IndexError:
            raise SystemExit(f"Usage: {sys.argv[0]} <webpage url>")
            print(arg[::-1])

    response = requests.get(url)
    text = response.text
    data = BeautifulSoup(text, 'html.parser')
    print(data.prettify())

if __name__ == "__main__":
        main()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
