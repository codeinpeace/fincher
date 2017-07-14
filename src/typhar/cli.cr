module Typhar
  class CLI < ::Cli::Supercommand
    version Typhar::VERSION
    command_name "typhar"

    class Options
      help
    end

    class Help
      header "Encodes a message as typos within a source text."
      footer "(C) 2017 Max Fierke"
    end

    class Encode < ::Cli::Command
      class Options
        arg "source_text_file", required: true, desc: "source text file"
        arg "message", required: true, desc: "message"
        string "--seed",
               var: "NUMBER",
               required: false,
               default: "",
               desc: "seed value. randomly generated if omitted"
        string "--displacement-strategy",
               var: "STRING",
               default: "word-offset",
               desc: "displacement strategy (Options: char-offset, word-offset)"
        string "--replacement-strategy",
               var: "STRING",
               default: "n-shifter",
               desc: "replacement strategy (Options: n-shifter)"
        string "--char-offset",
               var: "NUMBER",
               default: "130",
               desc: "character gap between typos (Displacement Strategies: char-offset)"
        string "--word-offset",
               var: "NUMBER",
               default: "38",
               desc: "word gap between typos (Displacement Strategies: word-offset)"
        string "--codepoint-shift",
               var: "NUMBER",
               default: "7",
               desc: "codepoints to shift (Replacement Strategies: n-shifter)"
      end

      class Help
        caption "encode message"
      end

      def run
        plaintext_scanner = ::IO::Memory.new(args.message)
        source_file = File.open(args.source_text_file)
        displacement_strategy = options.displacement_strategy
        replacement_strategy = options.replacement_strategy

        transformer = Typhar::Transformer.new(
          plaintext_scanner,
          source_file,
          displacement_strategy_for(displacement_strategy, plaintext_scanner, options),
          replacement_strategy_for(replacement_strategy, options)
        ).transform
      end

      private def displacement_strategy_for(strategy, plaintext_scanner, options)
        seed = options.seed.empty? ? generate_seed : options.seed.to_u32

        case strategy
        when "word-offset"
          word_offset = options.word_offset.to_i
          Typhar::DisplacementStrategies::MWordOffset.new(plaintext_scanner, seed, word_offset)
        when "char-offset"
          char_offset = options.char_offset.to_i
          Typhar::DisplacementStrategies::NCharOffset.new(plaintext_scanner, seed, char_offset)
        else
          raise StrategyDoesNotExistException.new("'#{strategy}' does not exist.")
        end
      end

      private def replacement_strategy_for(strategy, options)
        seed = options.seed.empty? ? generate_seed : options.seed.to_u32

        case strategy
        when "n-shifter"
          codepoint_shift = options.codepoint_shift.to_i
          Typhar::ReplacementStrategies::NShifter.new(seed, codepoint_shift)
        else
          raise StrategyDoesNotExistException.new("'#{strategy}' does not exist.")
        end
      end

      private def generate_seed
        SecureRandom.hex(4).to_u32(16)
      end
    end

    class Version < ::Cli::Command
      class Help
        caption "print the version"
      end

      def run
        puts "Typhar #{version}"
      end
    end
  end
end
