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

    try:
        response = requests.get(url)
        text = response.text
    except Exception as e:
        print(f"Unable to reach the url, error : {e}")
        sys.exit(1)
    
    try:
        data = BeautifulSoup(text, 'html.parser')
        for link in data.find_all('a'):
            print(link.get('href'))
    except Exception as e:
        print(f"Unable to render the webpage, error: {e}")
        sys.exit(1)

if __name__ == "__main__":
        main()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
