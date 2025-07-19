#!/usr/bin/env bash
set -e

# Usage helper
show_help() {
    cat <<EOF
Usage: ./run.sh <command>

Commands:
  start        Build and start all core services (web, processor, reader, redis, db).
  stop         Stop (but do not remove) containers.
  down         Stop and remove containers + network (keeps volume).
  destroy      Stop and remove everything INCLUDING db volume.
  scale N      Scale processor workers to N instances.
  test [N]     Run load tester with N requests (default 1000).
  like         Send one like (single POST) to web service.
  check        Show like counts for posts 1–3.
  logs         Follow processor logs.
  help         Show this help message.
EOF
}

# Internal helper to ensure compose command
dc() {
    docker compose "$@"
}

start_services() {
    echo "Building and starting services..."
    dc up -d --build
    echo "Services started."
}

stop_services() {
    echo "Stopping services..."
    dc stop
    echo "Services stopped."
}

down_services() {
    echo "Bringing down services (keeping volume)..."
    dc down
    echo "Done."
}

destroy_all() {
    echo "Bringing down services and removing volumes..."
    dc down -v
    echo "All containers and volumes removed."
}

scale_processors() {
    local n="$1"
    if [[ -z "$n" ]]; then
        echo "Specify number of processor replicas. Example: ./run.sh scale 3"
        exit 1
    fi
    echo "Scaling processor to $n replicas..."
    dc up -d --scale processor="$n"
    dc ps | grep processor || true
}

run_test() {
    local count=${1:-1000}
    echo "Running load test with $count requests..."
    # Ensure load_tester service exists in compose (uncomment or add it there)
    dc run --rm -e REQUEST_COUNT="$count" load_tester
}

send_like() {
    echo "Sending one like..."
    curl -s -X POST http://localhost:5000/like || {
        echo "Failed to send like"; exit 1;
    }
    echo
}

check_results() {
    echo "Post 1:"
    curl -s http://localhost:5001/likes/1 || echo
    echo
    echo "Post 2:"
    curl -s http://localhost:5001/likes/2 || echo
    echo
    echo "Post 3:"
    curl -s http://localhost:5001/likes/3 || echo
    echo
}

show_logs() {
    echo "Following processor logs (Ctrl+C to exit)..."
    dc logs -f processor
}

case "$1" in
    start)    start_services ;;
    stop)     stop_services ;;
    down)     down_services ;;
    destroy)  destroy_all ;;
    scale)    scale_processors "$2" ;;
    test)     run_test "$2" ;;
    like)     send_like ;;
    check)    check_results ;;
    logs)     show_logs ;;
    help|"")  show_help; exit 0 ;;
    *)        echo "Unknown command: $1"; show_help; exit 1 ;;
esac



# #!/bin/bash

# # A helper script to manage the Docker Compose setup.

# # Exit immediately if a command exits with a non-zero status.
# set -e

# # --- Helper Functions ---
# show_help() {
#     echo "Usage: ./run.sh [command]"
#     echo ""
#     echo "Commands:"
#     echo "  start     Build and start all services in detached mode."
#     echo "  stop      Stop all services."
#     echo "  down      Stop and remove all services, containers, and volumes."
#     echo "  test [N]  Run the load test with N requests (default: 1000)."
#     echo "  like      Send a single like to the system."
#     echo "  check     Check the like counts for the three posts."
#     echo "  reset     Reset the database by clearing the 'likes' table."
#     echo "  logs      Follow the logs of the processor services."
#     echo "  help      Show this help message."
# }

# # --- Main Commands ---
# start_services() {
#     echo "Building and starting services..."
#     docker-compose up -d --build --scale processor=3
#     echo "System started."
# }

# stop_services() {
#     echo "Stopping services..."
#     docker-compose stop
#     echo "System stopped."
# }

# tear_down() {
#     echo "Tearing down the system (including volumes)..."
#     docker-compose down -v
#     echo "System torn down."
# }

# run_test() {
#     local count=${1:-1000} # Default to 1000 if no argument is provided
#     echo "Running load test with $count requests..."
#     # Pass the count as an environment variable for reliability.
#     # The load_tester service will use its default CMD from the Dockerfile.
#     docker-compose --profile test run --rm -e REQUEST_COUNT="$count" load_tester
# }

# check_results() {
#     echo "Checking results..."
#     echo "--- Post 1 ---"
#     curl -s http://localhost:5002/likes/post:1 | sed 's/}/}\n/'
#     echo "--- Post 2 ---"
#     curl -s http://localhost:5002/likes/post:2 | sed 's/}/}\n/'
#     echo "--- Post 3 ---"
#     curl -s http://localhost:5002/likes/post:3 | sed 's/}/}\n/'
# }

# reset_database() {
#     echo "Resetting database..."
#     docker-compose --profile db-tools run --rm db_resetter
#     echo "Database reset."
# }

# show_logs() {
#     echo "Following processor logs... (Press Ctrl+C to stop)"
#     docker-compose logs -f processor
# }


# # --- Command Router ---
# case "$1" in
#     start)
#         start_services
#         ;;
#     stop)
#         stop_services
#         ;;
#     down)
#         tear_down
#         ;;
#     test)
#         run_test "$2"
#         ;;
#     like)
#         run_test 1
#         ;;
#     check)
#         check_results
#         ;;
#     reset)
#         reset_database
#         ;;
#     logs)
#         show_logs
#         ;;
#     help|*)
#         show_help
#         exit 1
#         ;;
# esac