TLS client/server pair
----------------------

To test using a browser:

    make
    make tlsd.pem
    ./tlsd.native -c tlsd.pem -h www.apache.org -p 80 -l 8081

then use a web client to visit https://localhost:8081/

To test the client/server pair, make the binaries as above, then in 3
terminals run:

    nc -l -p 8081
    ./tlsd.native -c tlsd.pem -h localhost -p 8081 -l 8082
    ./tlsc.native -h localhost -p 8082

The 'nc' command and the 'tlsc.native' commands should now each echo
what is typed into the other terminal.