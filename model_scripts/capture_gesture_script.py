# Cell 1: Setup
import cv2
import mediapipe as mp
import pandas as pd
import os
from datetime import datetime

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False,
                       max_num_hands=2,
                       min_detection_confidence=0.7,
                       min_tracking_confidence=0.5)
mp_drawing = mp.solutions.drawing_utils

DATA_DIR = "gesture_data"
os.makedirs(DATA_DIR, exist_ok=True)

current_label = "Good"
output_file = os.path.join(DATA_DIR, f"gesture_{current_label}.csv")



# Cell 2: Extract 2-hand landmarks (fills with 0s if one hand is missing)
def extract_both_hand_landmarks(results):
    hands_data = [[0.0] * 63, [0.0] * 63]  # Left, Right placeholders

    if results.multi_hand_landmarks and results.multi_handedness:
        for idx, hand_info in enumerate(results.multi_handedness):
            label = hand_info.classification[0].label  # "Left" or "Right"
            hand_landmarks = results.multi_hand_landmarks[idx]

            landmarks = []
            for lm in hand_landmarks.landmark:
                landmarks.extend([lm.x, lm.y, lm.z])

            if label == "Left":
                hands_data[0] = landmarks
            elif label == "Right":
                hands_data[1] = landmarks

    return hands_data[0] + hands_data[1]  # Combine both hands



# Cell 3: Capture & Save with 2-hand support
cap = cv2.VideoCapture(0)
saved = 0
delay_ms = 30  # Delay between recordings
frames_to_record = 2000
recording = False
record_count = 0
last_save_time = 0

print(f"[INFO] Press 's' to start recording {frames_to_record} frames for class '{current_label}'. Press 'q' to quit.")

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        continue

    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(frame_rgb)

    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            mp_drawing.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)

    cv2.putText(frame, f"Label: {current_label} | Saved: {saved}", (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

    if recording and (cv2.getTickCount() - last_save_time) > (delay_ms * cv2.getTickFrequency() / 1000):
        landmark_vector = extract_both_hand_landmarks(results)
        landmark_vector.append(current_label)
        df = pd.DataFrame([landmark_vector])
        df.to_csv(output_file, mode='a', header=not os.path.exists(output_file), index=False)
        saved += 1
        record_count += 1
        last_save_time = cv2.getTickCount()
        print(f"Recording... {record_count}/{frames_to_record}", end="\r")

        if record_count >= frames_to_record:
            recording = False
            record_count = 0
            print(f"\n[INFO] Finished recording {frames_to_record} frames for '{current_label}'")

    cv2.imshow("Hand Landmark Collector (Both Hands)", frame)
    key = cv2.waitKey(1)

    if key == ord('s') and not recording:
        print("[INFO] Starting recording...")
        recording = True
        record_count = 0
        last_save_time = cv2.getTickCount()
    elif key == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()