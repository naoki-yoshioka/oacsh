def glob_regexp(pattern)
  if pattern[0,1] != '*'
    pattern = '[^\w\^]' + pattern
  end
  if pattern[-1,1] != '*'
    pattern = pattern + '[^\w$]'
  end
  return Regexp.new(pattern.gsub(/\*/, '.*?'))
end

class OacshHome
  def name
    return "oacsh"
  end

  def ls(*simulator_names)
    if simulator_names.length == 0
      Simulator.each {|simulator| print simulator.name, " "}
    else
      regexps = simulator_names.map {|name| glob_regexp(name)}
      Simulator.each do |simulator|
        if regexps.any? {|regexp| regexp.match?(simulator.name)}
          print simulator.name, " "
        end
      end
    end

    puts
  end

#  def cd(simulator_name)
#    return self unless Simulator.where(name: simulator_name).exists?
#
#    return OacshSimulator.new(Simulator.find_by_name(simulator_name))
#  end
end

#class OacshSimulator
#  def initialize(simulator)
#    @simulator = simulator
#  end
#
#  def name
#    return @simulator.name
#  end
#
#  def ls(*parameter_sets)
#  end
#end

home = OacshHome.new
current_directory = home
print "#{current_directory.name}> "
$stdin.each do |line|
  inputs = line.split
  next if inputs.length == 0

  case inputs[0]
  when "exit", "quit"
    break if inputs.length == 1
  when "ls"
    current_directory.ls *inputs[1..-1]
  end

  print "#{current_directory.name}> "
end

