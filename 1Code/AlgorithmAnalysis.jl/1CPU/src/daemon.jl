using Sockets

function julia_daemon()
    server = listen(9001)
    println("Julia daemon is running on port 9001...")
    while true
        sock = accept(server)
        @async handle_client(sock)
    end
end

function handle_client(sock)
    try
        while isopen(sock)
            data = readline(sock)
            if data == "exit"
                println("Shutting down Julia daemon...")
                close(sock)
                break  # Exit the loop to stop the daemon
            elseif data != ""
                println("Received: ", data)
                write(sock, "Acknowledged\n")
                flush(sock)
            end
        end
    catch e
        println("Error: ", e)
    finally
        # Ensure the socket is closed after communication
        close(sock)
    end
end

julia_daemon()
