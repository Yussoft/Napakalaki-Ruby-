# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

require './CombatResult.rb'
require './Dice.rb'
require './Treasure.rb'
require './CardDealer.rb'
require './BadConsequence.rb'
require './Monster.rb'
require './TreasureKind.rb'

class Player
  def initialize(name, level, dead)
    @name = name
    @level = level
    @dead = dead
    @visibleTreasures = Array.new
    @hiddenTreasures = Array.new 
    @pendingBadConsequence = nil
  end
  
  attr_accessor :visibleTreasures,:hiddenTreasures,:level,:name,:dead,:pendingBadConsequence
  #-----------------------------------------------------------------------------
  private
  def bringToLife
    @dead = false
    @level = 1
  end
  
  public
  def to_s
    puts "#{@name} con nivel #{@level}"
  end
  
  public 
  #CONSTRUCTOR DE COPIA (P5)
  def copyPlayer(player)
    
    @level = player.level
    @pendingBadConsequence = player.pendingBadConsequence
    @dead = player.dead
    @visibleTreasures = player.visibleTreasures
    @hiddenTreasures = player.hiddenTreasures 
    
  end
  
  public
  def shouldConvert
    
    dice = Dice.instance
    if(dice.nextNumber == 6)
      puts "Ha salido 6 en el dado, te conviertes en cultista."
      return true
    else 
      return false
    end
    
    
  end
  #-----------------------------------------------------------------------------
=begin
  Para obtener el nivel de combate tenemos que sumar el nivel del jugador más
  los bonus que dan los tesoros equipados / visibles. Si hay collar el bonus es 
  el máximo, sino se aplica el bonus mínimo.
=end
  private 
  def getCombatLevel

    combatLevel = @level
    hasNecklace = false
    
    visibleTreasures.each do |treasure|
      
      if(treasure.type == "NECKLACE")
        hasNecklace = true
      end
      
      if(treasure.type != "NECKLACE" and hasNecklace)
        combatLevel=combatLevel+treasure.maxBonus
        
      elsif(treasure.type != "NECKLACE" and !hasNecklace)
        combatLevel=combatLevel+treasure.minBonus
      end
      
    end
    return combatLevel
  end
  #-----------------------------------------------------------------------------v
  private
  def incrementLevels(nlevels)
    if(@level + nlevels <= 10)
      @level = @level + nlevels
    end
  end
  #-----------------------------------------------------------------------------
  private
  def decrementLevels(nlevels)
    if(@level - nlevels >= 0)
      @level = @level - nlevels
    end
  end
  #-----------------------------------------------------------------------------
  private 
  def setPendingBadConsequence(badConsequence)
    @pendingBadConsequece = badConsequence
  end
  #-----------------------------------------------------------------------------
  private 
  def dieIfNoTreasure
    if(@visibleTreasures.size == 0  and @hiddenTreasures.size == 0)
      @dead = true
    end
  end
  #-----------------------------------------------------------------------------
  private
  def discardNecklaceIfVisible
    visibleTreasures.each do |treasure|
      if(treasure.type == [TreasureKind: "NECKLACE"])
        @cardDealer.giveTreasureBack(treasure)
        visibleTreasures.delete(treasure)        
      end
    end
  end
  #-----------------------------------------------------------------------------
  private
  
=begin
  Cuando el jugador muere en un combate, esta operación es la encargada de dejarlo
  sin tesoros, ponerle el nivel a 1 e indicar que está muerto, en el atributo 
  correspondiente
=end

  def die

     @level = 1
     dealer = CardDealer.instace
     
    @visibleTreasures.each do |t|
      dealer.giveTreasureBack(t)
    end
    @visibleTreasures.clear
    
    @hiddenTreasures.each do |h|
      dealer.giveTreasureBack(h)
    end
     
    @hiddenTreasures.clear
    
    dieIfNoTreasures
    
  end
  #-----------------------------------------------------------------------------
  private
  def computeGoldCoinsValue(treasures)
   
    total = 0
    treasures.each do |t|
      total = total + t.goldCoins
    end

    return total
  end
  #-----------------------------------------------------------------------------
  private 
  def canIBuyLevels(level)
    l = @level + level
    if(l >= 10)
      return false
    else true
    end
  end
  #-----------------------------------------------------------------------------
  private
  def applyPrice(currentMonster)
    nLevels = currentMonster.getLevelsGained
    incrementLevels(nLevels)
    nTreasures = currentMonster.getTreasuresGained
    
    if(nTreasures > 0)
      dealer = CardDealer.instance
      
      nTreasures.times do 
        treasure = dealer.nextTreasure
        @hiddenTreasures << treasure
      end
      
    end
  end
  #-----------------------------------------------------------------------------
  private
  def applyBadConsequence(badConsequence)
    nLevels = badConsequence.levels
    
    decrementLevels(nLevels)
    @pendingBadConsequence = badConsequence.adjustToFitTreasureList(@visibleTreasures, @hiddenTreasures)
    setPendingBadConsequence(@pendingBadConsequence)
    
  end
  #-----------------------------------------------------------------------------
  private
  def canMakeTreasureVisible(treasure)
    
    tipo = treasure.type
    contador = 0
    
    if(tipo == [TreasureKind: "ONEHAND"])
 
      contador = howManyVisibleTreasures([TreasureKind: "ONEHAND"])
      both = howManyVisibleTreasures([TreasureKind: "BOTHHANDS"])
      
      if(both == 0 and (contador == 0 or contador == 1))
        return true
      else 
        return false
      end  
      
      if(both == 1)
        return false
      end
      
      contador = 0 
    end
    
    if(tipo == [TreasureKind: "BOTHHANDS"])
      
      if(howManyVisibleTreasures(tipo) == 0)
        if(howManyVisibleTreasures([TreasureKind: "ONEHAND"]) == 0)
          return true
        end
      else
        return false
      end
      
    end
    
    #Resto de casos
    if(howManyVisibleTreasures(tipo) == 0)
      return true
    end
    
   
  end
  #-----------------------------------------------------------------------------
  private
  def howManyVisibleTreasures(tKind)
    contador = 0
    @visibleTreasures.each do |t|
      if(t.type == tKind)
        contador = contador + 1
      end
    end
  
    return contador
  end
  #-----------------------------------------------------------------------------
  public
  def isDead
    return @dead
  end
  #-----------------------------------------------------------------------------
  public 
  def getOponentLevel(monster)
    return monster.basicValue
  end
 
 
  #def getHiddenTreasures y visible por attr_accesor
  public 
  def combat(monster)
    myLevel = getCombatLevel
    monsterLevel = getOponentLevel(monster)
    combatResult = nil
    
    #WIN
    if(myLevel > monsterLevel)
      applyPrice(monster)
      if(@level >= 10)
        combatResult = :WIN
      end
      
    #LOSE
    else
      dice = Dice.instance
      escapar = dice.nextNumber
      
      if(escapar < 5)
        puts "Ha salido < 5 en el dado."
        amIDead = monster.kills
        #LOSEANDDIE
        if(amIDead)
          die
          puts "El monstruo tiene mal rollo de matar, has muerto."
          combatResult = :LOSEANDDIE
          
        elsif(shouldConvert)
          puts "Te vas a convertir en cultista."
          combatResult = :LOSEANDCONVERT
         
        #LOSE
        else
          badconsequence = monster.getBadConsequence
          badconsequence.to_s
          combatResult = :LOSE
          applyBadConsequence(badconsequence)
        end  
      #LOSEANDSCAPE  
      else
        combatResult = :LOSEANDSCAPE
      end 
    end
    
    discardNecklaceIfVisible
    return combatResult
  end
  #-----------------------------------------------------------------------------
  public 
  def makeTreasureVisible(treasure)
    canI = canMakeTreasureVisible(treasure)
    t = treasure.type
    if(canI)
      @visibleTreasures << treasure
      @hiddenTreasures.delete(treasure)
      puts "Se aniadido un tesoro de tipo #{t}."
    end
    
  end
  #-----------------------------------------------------------------------------
  public 
  def discardVisibleTreasure(treasure)
    
    @visibleTreasures.delete(treasure)
    if(@pendingBadConsequence != nil and (!@pendingBadConsequence.isEmpty))
      @pendingBadConsequence.substractVisibleTreasure(treasure)
    end
    dieIfNoTreasure
    
  end
  #-----------------------------------------------------------------------------
  public
  def discardHiddenTreasure(treasure)
    
    @hiddenTreasures.delete(treasure)
    if(@pendingBadConsequence != nil and (!@pendingBadConsequence.isEmpty))
      @pendingBadConsequence.substractHiddenTreasure(treasure)
    end
    dieIfNoTreasure
    
  end
  #-----------------------------------------------------------------------------
  public
  def buyLevels(visible, hidden)
    levelsMayBuy = computeGoldCoinsValue(visible)
    levelsMayBuy = levelsMayBuy + computeGoldCoinsValue(hidden)
    
    levels = levelsMayBuy/1000
    canI = canIBuyLevels(levels)
    
    if(canI)
      incrementLevels(levels)
    end
    
    #Se borran todos los tesoros
    @visibleTreasures.clear
    @hiddenTreasures.clear
    
    dealer = CardDealer.instance
    
    visible.each do |t|
      dealer.giveTreasureBack(t)
    end
    
     hidden.each do |h|
      dealer.giveTreasureBack(h)
    end
    
    return canI
  end
  #-----------------------------------------------------------------------------
  public 
  def validState
    #No PendingBadConsequence, isEmpty es método de BadConsequence
    
 
    return @pendingBadConsequence.isEmpty || @pendingBadConsequence == nil
  end
  #-----------------------------------------------------------------------------
  public 
  def initTreasures
    
    #1
    dealer = CardDealer.instance
    #2
    dice = Dice.instance
    #3
    bringToLife
    #4
    treasure = dealer.nextTreasure
    #5
    @hiddenTreasures << treasure
    
    number = dice.nextNumber
    puts "El numero del dado al inicializar tesoros es #{number}"
    if(number >= 2 and number <=5)
       treasure = dealer.nextTreasure
      @hiddenTreasures << treasure
    elsif(number == 6)
      2.times do 
        treasure = dealer.nextTreasure
        @hiddenTreasures << treasure
      end
    end
  end
  #-----------------------------------------------------------------------------
  public 
  def hasVisibleTreasures
    #Si no hay ninguna tesoro false, si tiene alguno true
    if(@visibleTreasures.empty?)
      return false
    else return true
    end
  end
  
  #METODOS NECESARIOS PARA GAME TESTER
  
  public
  def getVisibleTreasures
    return @visibleTreasures
  end
  
  public
  def getHiddenTreasures
    return @hiddenTreasures
  end
  
  public
  def to_s
    return " #{@name} || Nivel: #{@level} "
  end
end
