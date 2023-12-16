# typed: strict

require('sorbet-runtime')

module Util
    class << self
        extend(T::Sig)

        sig { returns(String) }
        def get_char
            state = `stty -g`
            `stty raw -echo -icanon isig`

            T.must(STDIN.getc).chr
        ensure
            `stty #{state}`
        end

        sig { void }
        def clear_screen
            print("\033c")
        end
    end
end

class WordExercise
    extend(T::Sig)

    sig { params(word: String, speaker: Speaker::Interface).void }
    def initialize(word, speaker)
        @word = word
        @speaker = speaker
        @buffer = T.let("", String)
    end

    sig { void }
    def run
        while true
            print_screen

            ch = Util.get_char

            exit if ch.ord == 27
            next if ch < 'a' || ch > 'z'

            @buffer += ch if ch == @word.chars[@buffer.size]

            if @word == @buffer
                @speaker.speak("Amazing! Lets do another one!")
                break
            end

            @speaker.speak(ch)
        end
    end

    sig { void }
    def print_screen
        Util.clear_screen

        print("\n\t#{@word.upcase}\n\n\t")

        @word.chars.each_with_index do |c, i|
            if @buffer.size > i
                print(c.upcase)
            else
                print("_")
            end
        end

        print("\n")
    end
end

class App
    extend(T::Sig)

    COLLECTION = T.let(
        [
            "apple",
            "dad",
            "mom",
            "ruby",
            "lennox",
        ],
        T::Array[String],
    )

    sig { void }
    def initialize
        @speaker = T.let(Speaker.build_for_os, Speaker::Interface)
    end

    sig { void }
    def run
        while true
            WordExercise.new(T.unsafe(COLLECTION.sample), @speaker).run
        end
    end
end

module Speaker
    extend(T::Sig)

    sig { returns(Interface) }
    def self.build_for_os
        return LinuxSpeaker.new if /linux/ =~ RUBY_PLATFORM
        return MacOsSpeaker.new if /darwin/ =~ RUBY_PLATFORM

        Kernel.raise("OS is not appropriate")
    end

    module Interface
        extend(T::Sig)
        extend(T::Helpers)

        interface!
        sealed!

        sig { abstract.params(sentence: String).void }
        def speak(sentence); end
    end

    class MacOsSpeaker
        extend(T::Sig)
        include(Interface)


        sig { override.params(sentence: String).void }
        def speak(sentence)
            Thread.new { system("say '#{sentence}'") }
        end
    end

    class LinuxSpeaker
        extend(T::Sig)
        include(Interface)


        sig { override.params(sentence: String).void }
        def speak(sentence)
            Thread.new { system("echo '#{sentence}' | espeak") }
        end
    end
end

App.new.run
