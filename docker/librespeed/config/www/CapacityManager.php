<?php
/**
 * CapacityManager.php
 * * Manages concurrent slots for speed tests to prevent server overload.
 * Uses a file-based lock for state persistence.
 *
 * @package MaxDiagnostic
 * @author Yago Borba
 */

class CapacityManager {
    // Defines the maximum number of concurrent tests (1000 Mbps / 500 Mbps per test)
    const MAX_CONCURRENT_TESTS = 1;
    // Maximum time (in seconds) a slot can be reserved before being considered 'stale' and automatically freed.
    const MAX_TEST_DURATION_SECONDS = 60; 
    // Path to the lock file. Needs to be writable by the web server process (www-data).
    const LOCK_FILE = '/tmp/speedtest_slots.json'; 

    /**
     * Reads the current state from the lock file, cleaning up any stale (timed-out) slots.
     *
     * @return array The current active slots.
     */
    private function getActiveSlots(): array {
        if (!file_exists(self::LOCK_FILE)) {
            return [];
        }

        $content = file_get_contents(self::LOCK_FILE);
        $slots = json_decode($content, true) ?? [];
        $currentTime = time();
        $cleanedSlots = [];

        // Cleanup stale slots
        foreach ($slots as $token => $data) {
            // Check if the slot has timed out
            if ($currentTime - $data['timestamp'] < self::MAX_TEST_DURATION_SECONDS) {
                $cleanedSlots[$token] = $data;
            } else {
                // Log the automatic cleanup for debugging/monitoring
                error_log("CapacityManager: Freed stale slot {$token}");
            }
        }
        
        return $cleanedSlots;
    }

    /**
     * Writes the current slot state back to the lock file.
     *
     * @param array $slots The slot array to save.
     * @return bool True on success, false on failure.
     */
    private function saveSlots(array $slots): bool {
        $json = json_encode($slots, JSON_PRETTY_PRINT);
        // Using LOCK_EX to prevent race conditions during write operations
        return file_put_contents(self::LOCK_FILE, $json, LOCK_EX) !== false;
    }

    /**
     * Checks the current server capacity.
     *
     * @return array The status array (OK, BUSY, OVERLOADED)
     */
    public function checkCapacity(): array {
        $slots = $this->getActiveSlots();
        $runningCount = count($slots);
        $slotsAvailable = self::MAX_CONCURRENT_TESTS - $runningCount;

        if ($slotsAvailable > 0) {
            return [
                'status' => 'OK', 
                'slots_available' => $slotsAvailable,
                'max_concurrent_tests' => self::MAX_CONCURRENT_TESTS
            ];
        }

        // Estimate wait time (simple approach: assumed max test duration)
        $waitTime = self::MAX_TEST_DURATION_SECONDS;
        
        return [
            'status' => 'BUSY', 
            'slots_available' => 0,
            'estimated_wait_seconds' => $waitTime
        ];
    }

    /**
     * Attempts to reserve a slot for a new test.
     * * @param string $clientId A unique identifier for the test/client (e.g., a UUID or device ID).
     * @return array The reservation status and token if granted.
     */
    public function reserveSlot(string $clientId): array {
        $slots = $this->getActiveSlots();
        $runningCount = count($slots);

        if ($runningCount < self::MAX_CONCURRENT_TESTS) {
            // Slot is available. Generate a unique token for the reservation.
            $token = uniqid('test_', true); 
            $slots[$token] = [
                'clientId' => $clientId,
                'timestamp' => time(),
            ];

            if ($this->saveSlots($slots)) {
                return [
                    'status' => 'GRANTED',
                    'token' => $token,
                    'max_duration_seconds' => self::MAX_TEST_DURATION_SECONDS
                ];
            } else {
                // Critical file write failure
                error_log("CapacityManager: CRITICAL failed to save slot reservation.");
                return ['status' => 'OVERLOADED', 'error' => 'Server state persistence failure.'];
            }
        }

        // No slot available
        return $this->checkCapacity(); // Returns status: BUSY
    }

    /**
     * Releases a previously reserved slot using the token.
     *
     * @param string $token The unique reservation token.
     * @return bool True if the slot was found and released, false otherwise.
     */
    public function releaseSlot(string $token): bool {
        $slots = $this->getActiveSlots(); // Clean up stale slots first
        
        if (isset($slots[$token])) {
            unset($slots[$token]);
            if ($this->saveSlots($slots)) {
                error_log("CapacityManager: Successfully released slot {$token}");
                return true;
            }
            // If save fails, the stale check mechanism will eventually clean it up.
            return false; 
        }

        // Slot not found (maybe already cleaned up by stale check or wrong token)
        error_log("CapacityManager: Attempted to release non-existent slot {$token}");
        return true; 
    }
}