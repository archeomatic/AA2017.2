## Variogramme directionnel 
## Ici, le variogramme est calcul� � partir des valeurs de l'�paisseur avec le fichier BDdepot2 (valeur mesur�es) mais le krigeage se fait avec le fichier BDdepot1 (correspond � BDdepot2 avec ajout de donn�es hypoth�tiques, non mesur�es)
## Script adapt� � partir des aides sur les library gstat, geoR et sp
## Script �crit en mars 2017 - Am�lie Laurent-Dehecq

#1 - Ouvrir les donn�es (A faire automatiquement depuis FILE/Import Dataset ou taper ci-dessous) + ATTENtion NE PAS UTILISER Excel mais export csv avec d�limiteurs ";" ou semicolon et les d�cimales avec des points
library(readr)
BDdepot2 <- read_delim("C:/Users/Am�lie/Desktop/Formation_ISA/R/BDdepot2.csv", ";", escape_double = FALSE, trim_ws = TRUE)
View(BDdepot2)

#2 - V�rification des donn�es (nb de donn�es, nb colonnes / noms des champs / r�sum� pour chaques variables)

library(gstat)
dim(BDdepot2)
names(BDdepot2)
summary(BDdepot2)

library(geoR)
geoBDdepot2<-as.geodata(BDdepot2,coords.col=2:3,data.col=6)
plot.geodata(geoBDdepot2)

#4 - Isotropie ou anisotropie = spatialisation de la variance. Il faut g�n�rer coordinates sur le DATA.frame sinon ne peut pas marcher

##4-1 - Pr�paration des donn�es
library(gstat)
library(sp)
head(BDdepot2)    #cr�er un identifiant unique devant tableau de donn�es
class(BDdepot2)   #> il faut obtenir :
                  #[1] "data.frame"
coordinates(BDdepot2)=~X+Y #D�finir les coordonn�es x et y en utlisant les nom des champs
class(BDdepot2)   #> il faut obtenir :
                      #[1] "SpatialPointsDataFrame"
                      #attr(,"package")
                      #[1] "sp"
summary(BDdepot2)
plot(BDdepot2)    #> cartographie des points (permet de v�rfier la carte)


##4-2a - Cartographie de la semi-variance de "Epaisseur" (cutoff = longueur max / witdh = taille de la cellule ou distance de voisinage/ thresold = seuil (nb paires de point�) -> il faut tenter plusieurs mesures pour visualiser les variations)
## "~1" veut dire qu'il n'y a une constance dans l'espace, on pourrait remplacer par un autre param�tre tel que le relief, voir l'aide sur ces fonctions
vario.map.Epaisseur = variogram((Epaisseur)~1, BDdepot2, cutoff = 1200, width = 100, map = TRUE)
plot(vario.map.Epaisseur , threshold = 10)
            ## Cela montre d�pendance directionnelle = anisotropie = faire variogramme directionnel par la suite


# 5 - Tracer les variogrammes directionnel

## 5-1a - Variogramme directionnel avec log(�paisseur) une tendance constante 
## avec angle (70� et 160�) et angle tol�rance 20�(pour avoir assez de paires de points)
##en imposant distance limite (cutoff) et le pas (width)

vario.Epaisseur = variogram((Epaisseur)~1, BDdepot2, cutoff = 1200, width = 100, alpha = c(70, 160), tol.hor = 20, cloud = FALSE)
vario.Epaisseur #d�clarer la variable = cr�er un type "gstat.variogram"
plot (vario.Epaisseur, type ="o", main = "Epaisseur - Variogamme exp�rimental 70 � et 160�") #type "o" = points calcul�s sont trac�s et reli�s
View (vario.Epaisseur)

## 5-1b exporter les valeurs du variogramme de Epaisseur
write.table(vario.Epaisseur, file = "C:/Users/Am�lie/Desktop/Formation_ISA/export/vario_Epaisseur_70_160.txt",sep=";")

## 5- 2 - Ajustement d'un mod�le (fit) de variogramme (fonction vgm) / Ici, psill et range sont donn�s � titre indicatif 
# si valeur de nugget non-mentionn�e, l'ajustement ne propose par d'effets de p�pite
# si fit.sills = TRUE => nugget et psill sont ajust�s automatiquement / si fit.sills = FALSE => nugget et psill sont ajust�s selon mon mod�le
# si fit.range = TRUE => range est ajust� automatiquement / # si fit.range = FALSE => range est ajust� manuellement
vario.Epaisseur.fit = fit.variogram (vario.Epaisseur , vgm(psill = 1.9, model = "Exp", range = 325, nugget = 1.1, anis = c(70, 0.66)), fit.sills = FALSE , fit.range = FALSE)
vario.Epaisseur.fit
plot(vario.Epaisseur,vario.Epaisseur.fit, type ="o", main = "Epaisseur_70_160 - Variogamme ajust�")

# 6 - Krigeage
## Pr�paration des donn�es de BDdepot1
###  Ouvrir les donn�es de BDdepot1 (A faire automatiquement depuis FILE/Import Dataset ou taper ci-dessous) + ATTENtion NE PAS UTILISER Excel mais export csv avec d�limiteurs ";" ou semicolon et les d�cimales avec des points
library(readr)
BDdepot1 <- read_delim("C:/Users/Am�lie/Desktop/Formation_ISA/R/BDdepot1.csv", ";", escape_double = FALSE, trim_ws = TRUE)
View(BDdepot1)

### pr�paration carto de BDdepot1
library(gstat)
library(sp)
head(BDdepot1)    #cr�er un identifiant unique devant tableau de donn�es
class(BDdepot1)   #> il faut obtenir :
#[1] "data.frame"
coordinates(BDdepot1)=~X+Y #D�finir les coordonn�es x et y en utlisant les nom des champs
class(BDdepot1)   #> il faut obtenir :
#[1] "SpatialPointsDataFrame"
#attr(,"package")
#[1] "sp"
summary(BDdepot1)
plot(BDdepot1)    #> cartographie des points (permet de v�rfier la carte)

## Cr�er un grid vide (limite de la fen�tre) = attention � la taille de la cellule en sortie, demande qq minutes pour kriger!
ouest<-474242.855888
est<-476935.196567
nord<-267752.513007
sud<-266551.203890
grx<- seq(ouest,est,by=1)
gry<- seq(sud,nord,by=1)
x<-rep(grx, length(gry))
y<-rep(gry, length(grx))
y<-sort(y, decreasing=F)
Grid<-data.frame(x=x, y=y)

coordinates(Grid)=~x+y
gridded(Grid)<-TRUE

class(Grid)

##Faire le krigeage de BDdepot1 � l'aide du mod�le d�fini dans BDdepot2 dans le grid

Epaisseur.kriged = krige((Epaisseur)~1, BDdepot1, Grid, model = vario.Epaisseur.fit)

###Affiche les valeurs estim�es

spplot(Epaisseur.kriged ["var1.pred"], main = "Estimation Epaisseur - krigeage ordinaire")

###Affiche la variance calcul�e

spplot(Epaisseur.kriged ["var1.var"], main = "ordinary kriging variance")

### exporter les r�sultats du krigeage de Epaisseur

library(rgdal) 
writeGDAL(Epaisseur.kriged, "C:/Users/Am�lie/Desktop/Formation_ISA/export/predict_Epaisseur_direct_choisi.tiff", drivername="GTiff")

# 7 - validation crois�e = pour valider le mod�le

Epaisseur.cv = krige.cv(Epaisseur~1, BDdepot1, model = vario.Epaisseur.fit)


### d�finition des titres d'axes
Epaisseur_mesur� = Epaisseur.cv$observed
Epaisseur_estim� = Epaisseur.cv$var1.pred

### tracer le graphique
plot(Epaisseur_mesur�, Epaisseur_estim�, main = "validation crois�e" )

###exporter les valeurs de la validation crois�e de Epaisseur

write.table (Epaisseur.cv, file = "C:/Users/Am�lie/Desktop/Formation_ISA/export/validation_croisee_Epaisseur.txt",sep=";") 

### calcul coefficient de corr�lation entre 2 variables
## on teste H0 = 0 vaec un alpha de 0.05. Si p-value < 0.05 alors Ho rejet�e donc corefficient de corr�lation repr�sentatif
cor(Epaisseur_mesur�, Epaisseur_estim�, method = c("pearson"))
cor.test(Epaisseur_mesur�, Epaisseur_estim�, method=c("pearson"))

# 8 - Si besoin de tester la m�thode d'interpolation inverse � la distance : IDW
Epaisseur.idw = idw(Epaisseur~1, BDdepot2, Grid)
class(Epaisseur.idw)
spplot(Epaisseur.idw ["var1.pred"], main = "Estimation - IDW")



