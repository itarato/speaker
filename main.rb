# typed: strict

require('sorbet-runtime')

class WordExercise
    extend(T::Sig)

    sig { params(word: String).void }
    def initialize(word)
        @word = word
    end

    sig { void }
    def run
    end
end

class Speaker
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
    end

    sig { void }
    def run
        while true
            WordExercise.new(T.unsafe(COLLECTION.sample)).run
        end
    end
end

Speaker.new.run
