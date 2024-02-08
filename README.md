# SpeechCraft

## Overview

SpeechCraft is a mobile application designed to enhance speech signals in noisy environments and transmit them to Bluetooth audio devices. The app employs cutting-edge deep learning models developed with SpeechBrain, a powerful toolkit for speech processing tasks.

## Features

- **Speech Separation:** Utilizes SpeechBrain's speech separation model to isolate and extract human speech from background noise.
- **Speech Enhancement:** Enhances the quality and intelligibility of speech signals by reducing noise and improving clarity.

## Installation

To use SpeechCraft, follow these steps:

1. Clone the repository to your local machine.
2. Install the necessary dependencies by running `pip install -r requirements.txt`.
3. Set up the Flask server by navigating to the `Python-Backend` directory and running `flask run`.
4. Use localtunnel to expose the Flask server to the internet for remote access.
5. Install the Flutter app on your mobile device and configure it to communicate with the Flask server.

## Usage

1. Launch the SpeechCraft app on your mobile device.
2. Record a voice or upload a pre-recorded audio file.
3. Choose the desired operation: speech separation or speech enhancement.
4. Initiate the process and wait for the results.
5. Connect your Bluetooth audio device to your mobile device.
6. Transmit the processed speech signals to the connected Bluetooth device for playback.

## Technologies Used

- **SpeechBrain:** Deep learning toolkit for speech processing tasks.
- **Flask:** Python web framework for building the backend server.
- **Flutter:** Cross-platform framework for building the mobile app.
- **localtunnel:** Tool for exposing local servers to the internet.
- **Bluetooth:** Wireless communication protocol for audio transmission.

## Contributors


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.