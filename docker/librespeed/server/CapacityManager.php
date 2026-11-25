<?php
/**
 * CapacityManager.php
 *
 * Limits how many speed tests run at the same time so concurrent tests do
 * not saturate the server link and distort each other's results.
 *
 * Slots are kept in a small JSON file. Every read-modify-write happens under
 * an exclusive lock, so two clients arriving together cannot both take the
 * last free slot.
 *
 * Configuration (environment variables of the container):
 *   MAX_CONCURRENT_TESTS       slots available at the same time (default 1)
 *   MAX_TEST_DURATION_SECONDS  seconds before a slot that was never released
 *                              is considered stale and freed (default 60)
 *
 * @package MaxDiagnostic
 * @author Yago Borba
 */

class CapacityManager {
    const DEFAULT_MAX_CONCURRENT_TESTS = 1;
    const DEFAULT_MAX_TEST_DURATION_SECONDS = 60;
    const DEFAULT_LOCK_FILE = '/tmp/speedtest_slots.json';

    private int $maxConcurrentTests;
    private int $maxTestDurationSeconds;
    private string $lockFile;

    public function __construct(?int $maxConcurrentTests = null, ?int $maxTestDurationSeconds = null, ?string $lockFile = null) {
        $this->maxConcurrentTests = max(1, $maxConcurrentTests ?? self::envInt('MAX_CONCURRENT_TESTS', self::DEFAULT_MAX_CONCURRENT_TESTS));
        $this->maxTestDurationSeconds = max(1, $maxTestDurationSeconds ?? self::envInt('MAX_TEST_DURATION_SECONDS', self::DEFAULT_MAX_TEST_DURATION_SECONDS));
        $this->lockFile = $lockFile ?? self::DEFAULT_LOCK_FILE;
    }

    private static function envInt(string $name, int $default): int {
        $value = getenv($name);
        return ($value !== false && ctype_digit($value)) ? (int) $value : $default;
    }

    /**
     * Runs $operation on the current slots while holding an exclusive lock.
     * The callback receives the slots (stale ones already removed) by
     * reference; whatever it leaves in the array is saved.
     */
    private function withSlots(callable $operation) {
        $handle = fopen($this->lockFile, 'c+');
        if ($handle === false) {
            throw new RuntimeException('Cannot open the slot state file.');
        }

        try {
            if (!flock($handle, LOCK_EX)) {
                throw new RuntimeException('Cannot lock the slot state file.');
            }

            $content = stream_get_contents($handle);
            $slots = json_decode($content ?: '[]', true);
            if (!is_array($slots)) {
                $slots = [];
            }

            $now = time();
            foreach ($slots as $token => $data) {
                if ($now - ($data['timestamp'] ?? 0) >= $this->maxTestDurationSeconds) {
                    unset($slots[$token]);
                    error_log("CapacityManager: freed stale slot {$token}");
                }
            }

            $result = $operation($slots);

            ftruncate($handle, 0);
            rewind($handle);
            fwrite($handle, json_encode($slots, JSON_PRETTY_PRINT));
            fflush($handle);

            return $result;
        } finally {
            flock($handle, LOCK_UN);
            fclose($handle);
        }
    }

    private function busy(): array {
        return [
            'status' => 'BUSY',
            'slots_available' => 0,
            'max_concurrent_tests' => $this->maxConcurrentTests,
            'estimated_wait_seconds' => $this->maxTestDurationSeconds,
        ];
    }

    /**
     * Reports whether a test could start now.
     *
     * @return array status OK with the free slots, or BUSY with an estimated wait.
     */
    public function checkCapacity(): array {
        return $this->withSlots(function (array &$slots) {
            $available = $this->maxConcurrentTests - count($slots);
            if ($available > 0) {
                return [
                    'status' => 'OK',
                    'slots_available' => $available,
                    'max_concurrent_tests' => $this->maxConcurrentTests,
                ];
            }
            return $this->busy();
        });
    }

    /**
     * Reserves a slot for a new test.
     *
     * @param string $clientId identifier of the device or test.
     * @return array GRANTED with a token, or BUSY.
     */
    public function reserveSlot(string $clientId): array {
        return $this->withSlots(function (array &$slots) use ($clientId) {
            if (count($slots) >= $this->maxConcurrentTests) {
                return $this->busy();
            }

            $token = bin2hex(random_bytes(16));
            $slots[$token] = [
                'clientId' => substr($clientId, 0, 128),
                'timestamp' => time(),
            ];

            return [
                'status' => 'GRANTED',
                'token' => $token,
                'max_duration_seconds' => $this->maxTestDurationSeconds,
            ];
        });
    }

    /**
     * Releases a reserved slot. Unknown or expired tokens are ignored.
     *
     * @return bool true if the token was holding a slot.
     */
    public function releaseSlot(string $token): bool {
        return $this->withSlots(function (array &$slots) use ($token) {
            if (!isset($slots[$token])) {
                return false;
            }
            unset($slots[$token]);
            return true;
        });
    }
}
