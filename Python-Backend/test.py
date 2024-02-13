from speechbrain.inference.separation import SepformerSeparation as separator
import torchaudio

model = separator.from_hparams(source="speechbrain/sepformer-whamr-enhancement", savedir='pretrained_models/sepformer-whamr-enhancement4')

# Correct path using raw string literal (r"") to avoid escaping issues
enhanced_speech = model.separate_file(path=r"D:\SpeechCraft\Python-Backend\audio.wav")
