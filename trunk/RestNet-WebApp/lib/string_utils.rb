class StringUtils
  def self.generate_random_words(max=100)
    Array.new(max) {(rand(122-97) + 97).chr }.join
  end
end