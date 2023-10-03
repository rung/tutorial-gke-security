#!/usr/bin/env python3

from bottle import route, run, template, request
import io
import pycurl


@route("/")
def hello():
    return template("index.html")


@route("/get_contents", method="POST")
def get_contents():
    url = request.forms.get("url")
    curl = pycurl.Curl()
    curl.setopt(pycurl.URL, url)
    curl.setopt(pycurl.TIMEOUT, 15)
    buffer = io.BytesIO()
    curl.setopt(curl.WRITEDATA, buffer)
    curl.perform()
    body = buffer.getvalue().decode("utf-8")
    return template("get.html", contents=body)


run(host="0.0.0.0", port=8080, debug=True)
