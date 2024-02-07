import speechbrain as sb
from speechbrain.dataio.dataio import read_audio
from IPython.display import Audio
import torchaudio
from speechbrain.inference.separation import SepformerSeparation as separator
import warnings

# Suppress torchaudio warnings
warnings.filterwarnings("ignore", category=UserWarning, module="torchaudio")


model = separator.from_hparams(source="speechbrain/sepformer-wsj02mix", savedir='pretrained_models/sepformer-wsj02mix')
est_sources = model.separate_file(path='D:/SpeechCraft/AIBackend/test_mixture.wav')

signal = read_audio("D:/SpeechCraft/AIBackend/test_mixture.wav").squeeze()
Audio(signal, rate=8000)

output_folder = 'D:/SpeechCraft/AIBackend/separated_sources/'

# Create and save the separated sources dynamically
for i in range(est_sources.size(est_sources.size(2))):
    output_file_path = f'{output_folder}separated_source_{i+1}.wav'
    torchaudio.save(output_file_path, est_sources[:, :, i], 8000)
    print(f'Separated source {i+1} saved to {output_file_path}')











import os

# Get the current working directory
current_dir = os.getcwd()

# Define the relative path from the current directory
relative_path = 'AIBackend/'

# Join the current directory with the relative path
full_path = os.path.join(current_dir, relative_path)

# Print the resulting path
print("Current Directory:", current_dir)
print("Full Path:", full_path)


# import speechbrain as sb
# from speechbrain.dataio.dataio import read_audio
# from IPython.display import Audio
# import torchaudio
# from speechbrain.inference.separation import SepformerSeparation as separator
# import warnings

# # Suppress torchaudio warnings
# warnings.filterwarnings("ignore", category=UserWarning, module="torchaudio")


# model = separator.from_hparams(source="speechbrain/sepformer-whamr-enhancement", savedir='pretrained_models/sepformer-whamr-enhancement4')
# enhanced_speech = model.separate_file(path='D:/SpeechCraft/AIBackend/example_whamr.wav')


# signal = read_audio("D:/SpeechCraft/AIBackend/example_whamr.wav").squeeze()

# output_file_path = 'D:/SpeechCraft/AIBackend/separated_source_1.wav'

# torchaudio.save(output_file_path, enhanced_speech[:, :, 0], 8000)













import speechbrain as sb
from speechbrain.dataio.dataio import read_audio
from IPython.display import Audio
import torchaudio

from speechbrain.inference.separation import SepformerSeparation as separator

model = separator.from_hparams(source="speechbrain/sepformer-wsj02mix", savedir='pretrained_models/sepformer-wsj02mix')
est_sources = model.separate_file(path='D:/SpeechCraft/AIBackend/test_mixture.wav')


signal = read_audio("D:/SpeechCraft/AIBackend/test_mixture.wav").squeeze()
Audio(signal, rate=8000)

#Audio(est_sources[:, :, 0].detach().cpu().squeeze(), rate=8000)

#Audio(est_sources[:, :, 1].detach().cpu().squeeze(), rate=8000)


output_file_path_1 = 'D:/SpeechCraft/AIBackend/separated_source_1.wav'
output_file_path_2 = 'D:/SpeechCraft/AIBackend/separated_source_2.wav'
output_file_path_3 = 'D:/SpeechCraft/AIBackend/separated_source_3.wav'

# Save the separated sources
torchaudio.save(output_file_path_1, est_sources[:, :, 0], 8000)
torchaudio.save(output_file_path_2, est_sources[:, :, 1], 8000)
torchaudio.save(output_file_path_3, est_sources[:, :, 2], 8000)




from speechbrain.inference.separation import SepformerSeparation as separator
import torchaudio

model = separator.from_hparams(source="speechbrain/sepformer-whamr-enhancement", savedir='pretrained_models/sepformer-whamr-enhancement4')
enhanced_speech = model.separate_file(path='D:/SpeechCraft/AIBackend/example_whamr.wav')


signal = read_audio("D:/SpeechCraft/AIBackend/example_whamr.wav").squeeze()
Audio(signal, rate=8000)

Audio(enhanced_speech[:, :].detach().cpu().squeeze(), rate=8000)