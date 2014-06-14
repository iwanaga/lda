require 'CSV'
require 'pp'

class Lda
  def initialize(n_topics, n_iteration, alpha, beta, input)
    @n_topics         = n_topics
    @n_iteration      = n_iteration
    @alpha            = alpha
    @beta             = beta
    @input            = input
    @topic_randomizer = Random.new(1)
    @csv              = []
    # [ [word, count per document, topic id], ... ]
    @data             = []
    # [ [word, topic_id], ... ]
    @dict             = []

    load_csv
    format_input_by_document
    initial_allocation

    @n_uniq_words = number_of_uniq_words
  end

  def load_csv
    CSV.foreach(@input) do |row|
      row[0] = row[0].to_i
      row[2] = row[2].to_i
      @csv.push row
    end
    @csv.shift
  end

  def format_input_by_document
    current_document_id = 0
    @csv.each do |row|
      document_id = row.shift
      if current_document_id != document_id
        @data.push []
        current_document_id = document_id
      end
      @data.last.push row
    end
  end

  def initial_allocation
    @data.each do |doc|
      @dict.push []
      doc.each do |word|
        count = word[1]
        count.times do
          @dict.last.push [word[0], allocate_topic]
        end
      end
    end
  end

  def update_topic
    @n_topics.times do |topic_id|
      nt = get_nt(topic_id)
      @dict.each do |doc|
        ntd = get_ntd(topic_id, doc)
        @dict.each do |word|
          # p(z = t | w, d), not normalized
          (@alpha + ntd) * (@beta + get_nwt(topic_id, word)) / (@beta * @n_uniq_words + nt)
        end
      end
    end
  end

  def get_nt(topic_id)
    return_value = 0
    @dict.each do |doc|
      doc.each do |word|
        if word[1] == topic_id
          return_value += 1
        end
      end
    end
    return_value
  end

  def get_ntd(topic_id, doc)
    doc.count { |word| word[1] == topic_id }
  end

  def get_nwt(topic_id, word)
    return_value = 0
    @dict.each do |doc|
      return_value += doc.select {|w| w[1] == topic_id && w[0] == word }.length
    end
    return_value
  end

  def number_of_uniq_words
    @data.flatten.delete_if {|x| x.is_a?(Integer)}.uniq.length
  end

  def allocate_topic
    @topic_randomizer.rand(0 ... 5)
  end

  def print
    #pp @data.last
    pp @n_uniq_words
    pp @dict.last
  end
end


N_TOPIC     = 5
N_ITERATION = 1
ALPHA       = N_TOPIC / 50
BETA        = 0.1

lda = Lda.new(N_TOPIC, N_ITERATION, ALPHA, BETA, '../data/in1_small.csv')
lda.print
#lda.update_topic
