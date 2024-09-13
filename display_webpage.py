#!/usr/bin/python3

'''
  Programname :
  Author :
  Version :
  Description
'''

import requests
import sys
import html2text

def main():


    try:
        url = str(sys.argv[1])
    except IndexError:
            raise SystemExit(f"Usage: {sys.argv[0]} <webpage url>")
            print(arg[::-1])

    try:
        response = requests.get(url)
    except Exception as e:
        print(f"Unable to reach the url, error : {e}")
        sys.exit(1)
    
    try:
        to_text = html2text.HTML2Text()
        to_text.ignore_links = True
        to_text.bypass_tables = False
        text = to_text.handle(response.text)
        print(text)
    except Exception as e:
        print(f"Unable to render the webpage, error: {e}")
        sys.exit(1)

if __name__ == "__main__":
        main()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
