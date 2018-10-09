def glob_regex(pattern)
  unless pattern[0,1] == '*'
    pattern = '^' + pattern
#    pattern = '[^\w\^]' + pattern
  end

  unless pattern[-1,1] == '*'
    pattern = pattern + '$'
#    pattern = pattern + '[^\w$]'
  end

  return Regexp.new(pattern.gsub(/\*/, '.*?'))
end

def present_directory(mode_history)
  unless mode_history.length >= 1
    puts "oacis: unrecoverable error"
    exit
  end

  result = mode_history[0].name.dup
  mode_history[1..-1].each {|mode| result << "/#{mode.name}"}
  return result
end

class OacshHome
  @@commands = ['commands', 'ls', 'cd']
  attr_reader :name

  def initialize
    @name = '~'
  end

  def interpret(words, mode_history)
    unless mode_history.length == 1
      puts "oacis: unrecoverable error"
      exit
    end

    case words[0]
    when @@commands[0]
      unless words.length == 1
        puts "#{present_directory(mode_history)}: #{@@commands[0]}: too many arguments"
      end
      print @@commands[0]
      @@commands[1..-1].each {|command| print ' ', command}
      puts

    when @@commands[1]
      list(words[1..-1])

    when @@commands[2]
      unless words.length == 2
        puts "#{present_directory(mode_history)}: #{@@commands[2]}: too many arguments"
        return
      end

      change_to(words[1], mode_history)

    else
      puts "#{present_directory(mode_history)}: #{words[0]}: command not found"
    end
  end

  private
  def list(simulator_names)
    if simulator_names.length == 0
      Simulator.each {|simulator| print simulator.name, ' '}
    else
      regexes = simulator_names.map {|name| glob_regex(name)}
      Simulator.each {|simulator| print simulator.name, ' ' if regexes.any? {|regex| regex.match?(simulator.name)}}
    end

    puts
  end

  def change_to(simulator_name, mode_history)
    return if simulator_name == '.'
    return if simulator_name == '~'
    return if simulator_name == '..'

    unless Simulator.where(name: simulator_name).exists?
      puts "#{present_directory(mode_history)}: #{@@commands[1]}: no #{simulator_name}"
      return
    end

    mode_history.push(OacshSimulator.new(Simulator.find_by_name(simulator_name)))
  end
end

class OacshSimulator
  @@commands = ['commands', 'cd', 'params']
  attr_reader :simulator, :name

  def initialize(simulator)
    @simulator = simulator
    @name = @simulator.name
  end

  def interpret(words, mode_history)
    unless mode_history.length >= 2
      puts "oacis: unrecoverable error"
      exit
    end

    case words[0]
    when @@commands[0]
      unless words.length == 1
        puts "#{present_directory(mode_history)}: #{@@commands[0]}: too many arguments"
      end
      print @@commands[0]
      @@commands[1..-1].each {|command| print ' ', command}
      puts

    when @@commands[1]
      unless words.length == 2
        puts "#{present_directory(mode_history)}: #{@@commands[1]}: too many arguments"
        return
      end

      change_to(words[1], mode_history)

    when @@commands[2]
      unless words.length == 1
        puts "#{present_directory(mode_history)}: #{@@commands[2]}: too many arguments"
        return
      end

      parameters()

    else
      puts "#{present_directory(mode_history)}: #{words[0]}: command not found"
    end
  end

  private
  def change_to(name, mode_history)
    return if name == '.'

    if name == '..'
      mode_history.pop
    elsif name == '~'
      mode_hisotry.slice!(1..-1)
    else
      puts "#{present_directory(mode_history)}: no #{name}"
    end
  end

  def parameters
    @simulator.default_parameters.each_key {|key| print key, ' '}
    puts
  end
end

def print_prompt(mode_history)
  print "[oacis #{present_directory(mode_history)}]$ "
end

mode_history = [OacshHome.new]
print_prompt(mode_history)

$stdin.each do |line|
  words = line.split
  next if words.length == 0

  case words[0]
  when "exit", "quit"
    unless words.length == 1
      puts "#{present_directory(mode_hisotry)}: #{words[0]}: too many arguments"
      next
    end

    puts "Leaving oacsh"
    break

  else
    mode_history.last.interpret(words, mode_history)
  end

  print_prompt(mode_history)
end
