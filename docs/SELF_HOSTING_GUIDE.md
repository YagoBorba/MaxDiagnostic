# Self-Hosting Guide

MaxDiagnostic measures speed against a [LibreSpeed](https://github.com/librespeed/speedtest) server that you run. The repository has everything needed in `docker/librespeed`. There is no public server configured by default: until you point the app to yours, the speed test cannot run.

## 1. Start the server

Requirements: a machine with [Docker](https://docs.docker.com/get-docker/) and Docker Compose.

```bash
cd docker/librespeed
docker compose up -d
```

The server listens on port **7000**. Check it:

```bash
curl http://localhost:7000/api.php?action=check_capacity
# {"status": "OK", "slots_available": 1, "max_concurrent_tests": 1}
```

`./smoke-test.sh` in the same folder runs the full check used by CI (it starts and stops its own container).

## 2. Size the concurrent tests

Concurrent tests share the server link and distort each other's results, so the server only lets a limited number run at the same time. Set the limit before starting the container:

| Variable | Default | Meaning |
|---|---|---|
| `MAX_CONCURRENT_TESTS` | `1` | Tests allowed at the same time. A rule of thumb is the server link divided by the speed you want to measure per test: a 1 Gbps link and 500 Mbps tests give `2`. |
| `MAX_TEST_DURATION_SECONDS` | `60` | Seconds after which a slot that was never released is freed. |

```bash
MAX_CONCURRENT_TESTS=2 docker compose up -d
```

When the limit is reached, the app shows the queue with the estimated wait and starts automatically when a slot is free.

## 3. Point the app to the server

Create `.env` from the example at the project root:

```bash
cp .env.example .env
```

and set the runner URL:

```env
SPEED_TEST_URL=http://<server-address>:7000/librespeed_runner.html
```

- On an emulator or desktop with Docker on the same machine, `localhost` works (the Android emulator uses `10.0.2.2`).
- On a physical device, use the IP address of the server on the same network, or its public address.

`.env` is bundled as an asset, so rebuild the app (`flutter run` or `flutter build apk`) after changing it. It is not tracked by Git.

## 4. Exposing the server on the internet

- Put the server behind a reverse proxy with HTTPS (for example Caddy or Nginx with Let's Encrypt) and use the `https://` URL in `SPEED_TEST_URL`.
- Keep `MAX_CONCURRENT_TESTS` within what the link can carry; it is also what protects the server from a burst of tests.
- Measure from a server close to your users: results include the path between the device and the server.

## Capacity API

| Request | Response |
|---|---|
| `GET /api.php?action=check_capacity` | `200 {"status":"OK","slots_available":n}` or `429 {"status":"BUSY","estimated_wait_seconds":s}` |
| `POST /api.php?action=reserve_slot&clientId=<id>` | `200 {"status":"GRANTED","token":"...","max_duration_seconds":s}` or `429 BUSY` |
| `GET /api.php?action=release_slot&token=<token>` | `200 {"status":"success"}` (unknown or expired tokens are ignored) |
| Slot state unavailable | `503 {"status":"OVERLOADED"}`: the app stops and reports the server as unavailable |
