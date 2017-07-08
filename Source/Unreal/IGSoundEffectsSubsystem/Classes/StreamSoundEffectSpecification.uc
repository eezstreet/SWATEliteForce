class StreamSoundEffectSpecification extends SoundEffectSpecification
    native;

// ============================================================================
// StreamSoundEffectSpecification
//  
// A StreamSoundEffectSpecification is an SoundEffectSpecification that handles creation
// of streaming sounds, and the data the sound designer needs to edit for their creation.
//
// ============================================================================

// Type of stream being played
enum ESoundStreamType
{   
    ADPCM,          // lower quality, smaller files
    PCM             // higher quality, larger files
};

var private config array<string>            Streams;            // List of stream path+filenames of streams to play
var private config ESoundStreamType         StreamType;         // Type of stream, note, only one type is allowed for all the streams in this schema

// Hook overrides from SoundEffectSpecification...
simulated protected event InitHook();

// Set the flags up for streaming sounds...
simulated protected event SetNativeFlagsHook()
{
    NativeFlags += SF_Streaming;

    if (IsSeamlessLoop)
        NativeFlags += SF_LoopingStream;
}

// Create the soundsets from the list of streams...
simulated native protected event PopulateSoundsHook();

cpptext
{
    // This function registers the streams and precaches any necessary data
    UBOOL UStreamSoundEffectSpecification::RegisterStream(const FString& Filename, INT SampleRate=48000, INT Flags=0  );
}