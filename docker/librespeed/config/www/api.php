<?php
/**
 * api.php
 * * Central API endpoint for MaxDiagnostic server integrity and capacity management.
 *
 * @package MaxDiagnostic
 * @author Yago Borba
 */

// Load the CapacityManager class
require_once __DIR__ . '/CapacityManager.php';

header('Content-Type: application/json');
$manager = new CapacityManager();

// Simple router based on the 'action' query parameter
$action = $_GET['action'] ?? null;
$token = $_GET['token'] ?? null;
$clientId = $_GET['clientId'] ?? 'anonymous'; 

$response = [];
$httpStatus = 200;

try {
    switch ($action) {
        case 'check_capacity':
            // Endpoint: /api.php?action=check_capacity
            $response = $manager->checkCapacity();
            if ($response['status'] === 'BUSY') {
                $httpStatus = 429; // Too Many Requests, appropriate for BUSY state
            }
            break;

        case 'reserve_slot':
            // Endpoint: /api.php?action=reserve_slot&clientId=...
            $response = $manager->reserveSlot($clientId);
            if ($response['status'] === 'BUSY') {
                $httpStatus = 429; // Too Many Requests
            } elseif ($response['status'] === 'OVERLOADED') {
                 $httpStatus = 503; // Service Unavailable
            }
            break;

        case 'release_slot':
            // Endpoint: /api.php?action=release_slot&token=...
            if (!$token) {
                throw new Exception("Missing 'token' for release_slot action.");
            }
            $manager->releaseSlot($token);
            $response = ['status' => 'success', 'message' => 'Slot release processed.'];
            break;

        default:
            $httpStatus = 400;
            $response = ['status' => 'error', 'message' => 'Invalid or missing action.'];
            break;
    }
} catch (Exception $e) {
    $httpStatus = 500;
    $response = ['status' => 'error', 'message' => 'Internal server error: ' . $e->getMessage()];
    error_log("API Error: " . $e->getMessage());
}

http_response_code($httpStatus);
echo json_encode($response, JSON_PRETTY_PRINT);

?>