# encoding: utf-8
# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

require './Napakalaki.rb'
require './game_tester.rb'

module Test

  class EjemploMain
   
      def prueba
        
       test = GameTester.instance
     
       game = Napakalaki::Napakalaki.instance
   
       #Se prueba el juego con 2 jugadores
   
       test.play(game, 2);
       
      end
      
  end
  
    e = EjemploMain.new
    e.prueba()

end
