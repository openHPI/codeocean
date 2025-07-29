# Examples are based on the "Learning to program with Python - school version"
# course of the HPI student team for Python consists of the students 
# Selina Reinhard, Nina Ihde, Kira Grammel and the doctoral student Sebastian Serth.
#
# Course available at: https://open.hpi.de/courses/pythonjunior-schule2024

from turtle import *

def erstelle_turtle(x, y, rotationsWinkel = 0, shape = "triangle", color = "green"):
    steuerung = Turtle()
    steuerung.speed(0) # schnellste Animationsgeschwindigkeit, um sichtbare Bewegung zu vermeiden
    steuerung.shape(shape)
    steuerung.color(color)
    steuerung.right(rotationsWinkel)
    steuerung.penup()
    steuerung.goto(x, y)
    steuerung.direction = "stop" # nur für Kopf relevant
    return steuerung

rechts = erstelle_turtle(180, -160)
unten = erstelle_turtle(160, -180, 90)
links = erstelle_turtle(140, -160, 180)
oben = erstelle_turtle(160, -140, 270)
kopf = erstelle_turtle(0, 0, 0, "square", "black")

def setze_richtung(dahin, dahinNicht):
    # Vermeiden, dass Schlangenkopf zurück in sich selbst laufen kann
    if kopf.direction != dahinNicht:
        kopf.direction = dahin
        kopf_bewegen()
        
def kopf_bewegen():
    if kopf.direction == "down":
        y = kopf.ycor()
        kopf.sety(y - 20)

    elif kopf.direction == "right":
        x = kopf.xcor()
        kopf.setx(x + 20)
    
    elif kopf.direction == "up":
        y = kopf.ycor()
        kopf.sety(y + 20)

    elif kopf.direction == "left":
        x = kopf.xcor()
        kopf.setx(x - 20)

        
def checke_kollision_mit_fensterrand():
    if kopf.xcor() > 190 or kopf.xcor() < -190 or kopf.ycor() > 190 or kopf.ycor() < -190:
        spiel_neustarten()
        

def interpretiere_eingabe(x, y):
    if (x >= 170 and x <= 190 and y >= -170 and y <= -150):
        setze_richtung("right", "left")
    elif (x >= 150 and x <= 170 and y >= -190 and y <= -170):
        setze_richtung("down", "up")
    elif (x >= 130 and x <= 150 and y >= -170 and y <= -150):
        setze_richtung("left", "right")
    elif (x >= 150 and x <= 170 and y >= -150 and y <= -130):
        setze_richtung("up", "down")
    else:
        return None
    checke_kollision_mit_fensterrand()

def spiel_neustarten():
    kopf.goto(0, 0) 
    kopf.direction = "stop"

onclick(interpretiere_eingabe)
mainloop()
