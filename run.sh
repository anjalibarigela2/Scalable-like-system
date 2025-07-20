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