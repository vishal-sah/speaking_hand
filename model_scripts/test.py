import cv2
import mediapipe as mp
import numpy as np
import onnxruntime as ort

# --- Setup MediaPipe hands ---
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils

hands = mp_hands.Hands(static_image_mode=False, max_num_hands=2, min_detection_confidence=0.7)

# --- Load ONNX model ---
onnx_model_path = 'model_2.onnx'
session = ort.InferenceSession(onnx_model_path)
input_name = session.get_inputs()[0].name

# --- Define your class labels (order must match training order) ---
class_labels = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']  # replace with your actual labels

# --- Extract landmarks for both hands (like before) ---
def extract_both_hand_landmarks(results):
    all_landmarks = [0.0] * (2 * 21 * 3)  # 2 hands, 21 points, x,y,z
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
        # print(f"Input data shape: {input_data.shape}")
        # print(f"Input data: {input_data}")
        output = session.run(None, {input_name: input_data})[0]
        print(f"Raw output: {output}")

        # Get predicted class
        predicted_idx = int(output[0])  # Get the index of the highest probability
        predicted_label = class_labels[predicted_idx]

        # Draw prediction
        cv2.putText(frame, f"Prediction: {predicted_label}", (10, 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 255, 0), 3)
    else:
        predicted_label = ""

    cv2.imshow("Real-time Hand Sign Detection", frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()