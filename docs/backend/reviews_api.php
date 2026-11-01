<?php
// ============================================================
// reviews_api.php
// Member ratings & reviews for the PrimeFit landing page.
//
//   GET  reviews_api.php?action=list_reviews&page=1&limit=6
//        -> { success, reviews:[{ReviewID,name,rating,comment,created_at}],
//             count, average, total_pages, page }
//
//   POST reviews_api.php?action=submit_review
//        body: { "member_id": 4, "rating": 5, "comment": "..." }
//        -> { success, message }
//
// Plain PHP + mysqli, same pattern as membership_api.php / billing_api.php.
// Requires the Reviews table (see 2026_add_reviews_table.sql).
// ============================================================

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    http_response_code(200);
    exit();
}

require "db_connect.php";

$action = $_GET["action"] ?? "";

// Only these statuses are shown publicly. Change to just ['approved'] if
// you want every review moderated before it appears.
$VISIBLE_STATUSES = "'approved'";

// ------------------------------------------------------------
// list_reviews
// ------------------------------------------------------------
if ($action === "list_reviews") {
    $page  = max(1, intval($_GET["page"] ?? 1));
    $limit = min(24, max(1, intval($_GET["limit"] ?? 6)));
    $offset = ($page - 1) * $limit;

    // Aggregate over all visible reviews.
    $aggRes = $conn->query(
        "SELECT COUNT(*) AS c, AVG(Rating) AS a
         FROM Reviews WHERE Status IN ($VISIBLE_STATUSES)"
    );
    $agg = $aggRes ? $aggRes->fetch_assoc() : ["c" => 0, "a" => null];
    $count = intval($agg["c"]);
    $average = $agg["a"] === null ? 0.0 : round(floatval($agg["a"]), 1);
    $totalPages = $count === 0 ? 1 : (int)ceil($count / $limit);

    $stmt = $conn->prepare(
        "SELECT r.ReviewID,
                CONCAT(m.FirstName, ' ', LEFT(m.LastName, 1), '.') AS name,
                r.Rating, r.Comment, r.CreatedAt
         FROM Reviews r
         JOIN Members m ON m.MemberID = r.MemberID
         WHERE r.Status IN ($VISIBLE_STATUSES)
         ORDER BY r.CreatedAt DESC
         LIMIT ? OFFSET ?"
    );
    $stmt->bind_param("ii", $limit, $offset);
    $stmt->execute();
    $result = $stmt->get_result();

    $reviews = [];
    while ($row = $result->fetch_assoc()) {
        $reviews[] = [
            "ReviewID"   => intval($row["ReviewID"]),
            "name"       => $row["name"],
            "rating"     => intval($row["Rating"]),
            "comment"    => $row["Comment"],
            "created_at" => $row["CreatedAt"],
        ];
    }
    $stmt->close();
    $conn->close();

    echo json_encode([
        "success"     => true,
        "reviews"     => $reviews,
        "count"       => $count,
        "average"     => $average,
        "page"        => $page,
        "total_pages" => $totalPages,
    ]);
    exit();
}

// ------------------------------------------------------------
// submit_review
// ------------------------------------------------------------
if ($action === "submit_review") {
    if ($_SERVER["REQUEST_METHOD"] !== "POST") {
        echo json_encode(["success" => false, "message" => "POST required."]);
        exit();
    }

    $data = json_decode(file_get_contents("php://input"), true);
    if (!$data) {
        echo json_encode(["success" => false, "message" => "No data received."]);
        exit();
    }

    $memberId = intval($data["member_id"] ?? 0);
    $rating   = intval($data["rating"] ?? 0);
    $comment  = trim($data["comment"] ?? "");

    if ($memberId <= 0) {
        echo json_encode(["success" => false, "message" => "You must be signed in to leave a review."]);
        exit();
    }
    if ($rating < 1 || $rating > 5) {
        echo json_encode(["success" => false, "message" => "Rating must be 1 to 5 stars."]);
        exit();
    }
    if (mb_strlen($comment) < 4) {
        echo json_encode(["success" => false, "message" => "Please write a short comment."]);
        exit();
    }
    if (mb_strlen($comment) > 600) {
        $comment = mb_substr($comment, 0, 600);
    }

    // Member must exist.
    $mStmt = $conn->prepare("SELECT MemberID FROM Members WHERE MemberID = ?");
    $mStmt->bind_param("i", $memberId);
    $mStmt->execute();
    if (!$mStmt->get_result()->fetch_assoc()) {
        $mStmt->close();
        echo json_encode(["success" => false, "message" => "Member not found."]);
        exit();
    }
    $mStmt->close();

    // One review per member — update if they already have one.
    $exStmt = $conn->prepare("SELECT ReviewID FROM Reviews WHERE MemberID = ? LIMIT 1");
    $exStmt->bind_param("i", $memberId);
    $exStmt->execute();
    $existing = $exStmt->get_result()->fetch_assoc();
    $exStmt->close();

    if ($existing) {
        $upd = $conn->prepare(
            "UPDATE Reviews SET Rating = ?, Comment = ?, CreatedAt = NOW(), Status = 'pending'
             WHERE ReviewID = ?"
        );
        $rid = intval($existing["ReviewID"]);
        $upd->bind_param("isi", $rating, $comment, $rid);
        $ok = $upd->execute();
        $upd->close();
        $msg = "Your review has been updated and is awaiting approval.";
    } else {
        $ins = $conn->prepare(
            "INSERT INTO Reviews (MemberID, Rating, Comment, Status)
             VALUES (?, ?, ?, 'pending')"
        );
        $ins->bind_param("iis", $memberId, $rating, $comment);
        $ok = $ins->execute();
        $ins->close();
        $msg = "Thanks! Your review has been submitted for approval.";
    }

    $conn->close();
    echo json_encode([
        "success" => (bool)$ok,
        "message" => $ok ? $msg : "Could not save your review. Please try again.",
    ]);
    exit();
}

echo json_encode(["success" => false, "message" => "Unknown action."]);
$conn->close();
?>
