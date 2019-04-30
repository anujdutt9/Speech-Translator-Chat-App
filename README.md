# Speech Translator Chat App

***The "Speech Translator Chat App" is an iOS app that aims at solving the language barrier problem. Using this app two people who speak different languages can communicate with each other seamlessly.***

# App Demo

<img src="Host.gif" alt="" width="50%" height="30%"><img src="Reciever.gif" alt="" width="50%" height="30%">

# Tools Used

**1.** iOS [Multipeer Connectivity Framework](https://developer.apple.com/documentation/multipeerconnectivity) for sharing data between devices.

**2.** [Google Cloud Speech to Text](https://cloud.google.com/speech-to-text/) API

**3.** [Google Cloud Translate](https://cloud.google.com/translate/docs/reference/rest/) API

# App Usage/ Installation

**1.** From a terminal, run: ./INSTALL-COCOAPODS

**2.** Get your Google Cloud Speech to Text API Key and put it [here](https://github.com/anujdutt9/Speech-Translator-Chat-App/blob/17a13e6499082e204d0dd8bc2e5261029563110a/SpeechTranslator/SpeechRecognitionService.swift#L19)

**3.** Get your Google Cloud Translation API Key and put it [here](https://github.com/anujdutt9/Speech-Translator-Chat-App/blob/17a13e6499082e204d0dd8bc2e5261029563110a/SpeechTranslator/GoogleTranslate.swift#L32)

**4.** Run and Install the app on an iPhone.

**5.** Either Host a Translation session or Join an existing session (at a time, 7 people can join a chat session).

**6.** Every user can select their preferred language in which they speak in the app.

**7.** Click on Start Streaming button and speak in your preferred language.

**8.** The app takes in the speech and converts into the preferred language.

**9.** All other users in the session recieve this message and see it in their preferred language using translation service.

**10.** This communication is a two way communocation. Hence, anyone in the session can send and recieve the text.


# References

**1. Google Cloud Speech Streaming gRPC Swift Sample iOS App**
```
https://github.com/GoogleCloudPlatform/ios-docs-samples/tree/master/speech/Swift/Speech-gRPC-Streaming
```

**2. Google Cloud Text Translation API**
```
https://cloud.google.com/translate/docs/translating-text#translate_translate_text-cli-curl
```
