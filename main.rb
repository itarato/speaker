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

    MISTAKE_REPLY = T.let(
        [
            "Oh no. What a clumsy finger!",
            "Slow down baby!",
            "Hey! What is happening?",
            "Not good. Are you ok?",
        ],
        T::Array[String],
    )
    MISTAKE_REPLY_THRESHOLD = 4

    sig { params(word: String, speaker: Speaker::Interface).void }
    def initialize(word, speaker)
        @word = word
        @speaker = speaker
        @mistake_counter = T.let(0, Integer)
        @buffer = T.let("", String)
    end

    sig { void }
    def run
        print_screen
        3.times { @speaker.speak("#{@word}."); sleep(0.2) }

        while true
            print_screen

            ch = Util.get_char

            exit if ch.ord == 27
            next if ch < 'a' || ch > 'z'

            @speaker.speak_async(ch)

            if ch == @word.chars[@buffer.size]
                @buffer += ch
                @mistake_counter = 0
            else
                @mistake_counter += 1
            end

            if @mistake_counter >= MISTAKE_REPLY_THRESHOLD
                @mistake_counter = 0

                sleep(1)
                @speaker.speak(T.unsafe(MISTAKE_REPLY.sample))
            end

            if @word == @buffer
                print_screen

                sleep(1)
                @speaker.speak("Amazing! Lets do another one!")

                break
            end
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
            "ran",
            "man",
            "her",
            "here",
            "dog",
            "him",
            "cow",
            "home",
            "fat",
            "good",
            "ride",
            "his",
            "day",
            "cat",
            "like",
            "car",
            "box",
            "hot",
            "play",
            "ball",
            "cold",
            "bed",
            "yes",
            "book",
            "pan",
            "no",
            "far",
            "fun",
            "one",
            "tree",
            "lennox",
            "dad",
            "mom",
            "ruby",
            "house",
            "door",
            "pee",
            "poop",
            "butt",
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

        abstract!
        sealed!

        sig { abstract.params(sentence: String).void }
        def speak(sentence); end

        sig { params(sentence: String).void }
        def speak_async(sentence)
            Thread.new { speak(sentence) }
        end
    end

    class MacOsSpeaker
        extend(T::Sig)
        include(Interface)


        sig { override.params(sentence: String).void }
        def speak(sentence)
            system("say '#{sentence}'")
        end
    end

    class LinuxSpeaker
        extend(T::Sig)
        include(Interface)


        sig { override.params(sentence: String).void }
        def speak(sentence)
            system("echo '#{sentence}' | espeak")
        end
    end
end

App.new.run
