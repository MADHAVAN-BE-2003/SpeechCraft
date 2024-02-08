import zipfile
from flask import Flask, request, jsonify, send_file
import os
import io
import base64
import torchaudio
from speechbrain.dataio.dataio import read_audio
from speechbrain.inference.separation import SepformerSeparation as separator
import warnings

# Suppress torchaudio warnings
warnings.filterwarnings("ignore", category=UserWarning, module="torchaudio")

app = Flask(__name__)

# Load the separate model
separate_model = separator.from_hparams(source="speechbrain/sepformer-wsj02mix", savedir='pretrained_models/sepformer-wsj02mix')

# Load the enhancement model
enhancement_model = separator.from_hparams(source="speechbrain/sepformer-whamr-enhancement", savedir='pretrained_models/sepformer-whamr-enhancement4')

@app.route('/get/separate', methods=['POST'])
def get_separate():
    # Check if the post request has the file part
    if 'file' not in request.files:
        return jsonify({"error": "No file part"})

    file = request.files['file']

    # If the user does not select a file, browser also submits an empty file
    if file.filename == '':
        return jsonify({"error": "No selected file"})

    # Save the received audio file
    # Concatenate directory path and file name using os.path.join
    file_path = os.path.join(os.getcwd(), file.filename)
    file.save(file_path)

    # Separate sources
    est_sources = separate_model.separate_file(path=file_path)

    # Create and save the separated sources dynamically
    separated_sources = []
    for i in range(est_sources.size(2)):
        torchaudio.save(f"separated_source_{i + 1}.wav", est_sources[:, :, i], 8000)
        separated_sources.append(f"separated_source_{i + 1}.wav")

    zip_file_path = "separated_sources.zip"
    with zipfile.ZipFile(zip_file_path, 'w') as zipf:
        for source_file in separated_sources:
            zipf.write(source_file)

    return send_file(zip_file_path, as_attachment=True)

@app.route('/get/enhance', methods=['POST'])
def get_enhance():
    # Check if the post request has the file part
    if 'file' not in request.files:
        return jsonify({"error": "No file part"})

    file = request.files['file']

    # If the user does not select a file, browser also submits an empty file
    if file.filename == '':
        return jsonify({"error": "No selected file"})

    # Save the received audio file
    # Concatenate directory path and file name using os.path.join
    file_path = os.path.join(os.getcwd(), file.filename)
    file.save(file_path)

    # Enhance audio
    enhanced_speech = enhancement_model.separate_file(path=file_path)

    # Create and save the enhanced audio dynamically
    torchaudio.save("enhanced_source.wav", enhanced_speech[:, :, 0], 8000)

    return send_file("enhanced_source.wav", as_attachment=True)


if __name__ == '__main__':
    app.run(debug=True)
