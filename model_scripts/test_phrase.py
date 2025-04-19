import cv2
import mediapipe as mp
import numpy as np
import tensorflow as tf
import joblib

# --- Setup MediaPipe hands ---
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
hands = mp_hands.Hands(static_image_mode=False, max_num_hands=2, min_detection_confidence=0.7)

# --- Load TFLite model ---
interpreter = tf.lite.Interpreter(model_path='gesture_model_bothhands_new.tflite')
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# --- Load LabelEncoder ---
label_encoder = joblib.load("label_encoder_new.pkl")

import json

# Get class labels from fitted LabelEncoder
labels = label_encoder.classes_.tolist()

# Save to labels.txt (one label per line)
with open("labels.txt", "w") as f:
    for label in labels:
        f.write(f"{label}\n")

# --- Extract landmarks for both hands ---
def extract_both_hand_landmarks(results):
    all_landmarks = [0.0] * 445  # Adjust to match the model's input size
    if results.multi_hand_landmarks:
        for i, hand_landmarks in enumerate(results.multi_hand_landmarks):
            if i > 1:
                break
            for j in range(21):
                index = i * 63 + j * 3
                all_landmarks[index] = hand_landmarks.landmark[j].x
                all_landmarks[index + 1] = hand_landmarks.landmark[j].y
                all_landmarks[index + 2] = hand_landmarks.landmark[j].z
    return all_landmarks

# --- Start webcam ---
cap = cv2.VideoCapture(0)
predicted_label = ""

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(frame_rgb)

    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            mp_drawing.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)

        # Extract features and predict
        landmarks = extract_both_hand_landmarks(results)
        input_data = np.array([landmarks], dtype=np.float32)
        if input_data.shape[1] != input_details[0]['shape'][1]:
            raise ValueError(f"Input data shape mismatch: {input_data.shape[1]} vs {input_details[0]['shape'][1]}")
        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]['index'])
        print(f"Raw output: {output}")

        predicted_idx = np.argmax(output[0])
        predicted_label = label_encoder.inverse_transform([predicted_idx])[0]

        # Draw prediction
        cv2.putText(frame, f"Prediction: {predicted_label}", (10, 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 255, 0), 3)
    else:
        predicted_label = ""

    cv2.imshow("Real-time Hand Sign Detection (TFLite)", frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
