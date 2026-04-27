import {
  IonBackButton,
  IonButton,
  IonButtons,
  IonCol,
  IonContent,
  IonGrid,
  IonHeader,
  IonIcon,
  IonPage,
  IonRow,
  IonTitle,
  IonToolbar,
} from '@ionic/react'
import { ZendeskChat } from 'capacitor-zendesk-classic-sdk'
import {
  chatbubbleEllipsesOutline,
  chevronBackOutline,
  createOutline,
  documentTextOutline,
  receiptOutline,
} from 'ionicons/icons'
import React, { useEffect, useState } from 'react'
import styles from './Home.module.css'

const Home: React.FC = () => {
  const [initialized, setInitialized] = useState(false)
  const [liveChatEnabled, setLiveChatEnabled] = useState(false)

  useEffect(() => {
    const initialize = async () => {
      try {
        await ZendeskChat.initialize({
          appId: import.meta.env.VITE_ZENDESK_APP_ID,
          clientId: import.meta.env.VITE_ZENDESK_CLIENT_ID,
          zendeskUrl: import.meta.env.VITE_ZENDESK_URL,
          theme: {
            primaryColor: import.meta.env.VITE_ZENDESK_PRIMARY_COLOR,
          },
          enableLiveChat: false,
        })

        await ZendeskChat.setVisitorInfo({
          name: 'John Doe',
          email: 'john@example.com',
        })

        const { enabled } = await ZendeskChat.isLiveChatEnabled()
        setLiveChatEnabled(enabled)
        setInitialized(true)
      } catch (e) {
        console.error('Error initializing Zendesk', e)
      }
    }

    initialize()
  }, [])

  const openMessaging = async () => {
    await ZendeskChat.open({})
  }

  const openHelpCenter = async () => {
    await ZendeskChat.openHelpCenter({})
  }

  const openTicketList = async () => {
    await ZendeskChat.openTicketList()
  }

  const createTicket = async () => {
    await ZendeskChat.createTicket()
  }

  return (
    <IonPage className={styles.supportPage}>
      <IonHeader className='ion-no-border'>
        <IonToolbar>
          <IonButtons slot='start'>
            <IonBackButton
              defaultHref='/home'
              icon={chevronBackOutline}
              className={styles.backButton}
            />
          </IonButtons>
          <IonTitle>Hilfe & Support</IonTitle>
        </IonToolbar>
      </IonHeader>

      <IonContent className='ion-padding' scrollY={true}>
        <div className={styles.mainContainer}>
          {/* Hero Section */}
          <section className={styles.heroSection}>
            <h2 className={styles.heroHeadline}>Wie können wir dir helfen?</h2>
          </section>

          {/* Action Grid */}
          <IonGrid className='ion-no-padding'>
            <IonRow className={styles.actionColumn}>
              <IonCol size='12'>
                <button
                  className={`${styles.actionCard} group`}
                  onClick={openHelpCenter}
                >
                  <div className={`${styles.iconWrapper} ${styles.primaryBg}`}>
                    <IonIcon
                      icon={documentTextOutline}
                      className={styles.actionIcon}
                    />
                  </div>
                  <div className={styles.cardContent}>
                    <h3 className={styles.cardTitle}>Help Center</h3>
                    <p className={styles.cardDescription}>
                      Antworten auf die häufigsten Fragen finden.
                    </p>
                  </div>
                </button>
              </IonCol>

              {liveChatEnabled && (
                <IonCol size='12'>
                  <button
                    className={`${styles.actionCard} group`}
                    onClick={openMessaging}
                  >
                    <div
                      className={`${styles.iconWrapper} ${styles.secondaryBg}`}
                    >
                      <IonIcon
                        icon={chatbubbleEllipsesOutline}
                        className={styles.actionIcon}
                      />
                    </div>
                    <div className={styles.cardContent}>
                      <h3 className={styles.cardTitle}>Live Chat</h3>
                      <p className={styles.cardDescription}>
                        Direkte Hilfe von unserem Support-Team.
                      </p>
                    </div>
                  </button>
                </IonCol>
              )}

              <IonCol size='12'>
                <button
                  className={`${styles.actionCard} group`}
                  onClick={openTicketList}
                >
                  <div className={`${styles.iconWrapper} ${styles.grayBg}`}>
                    <IonIcon
                      icon={receiptOutline}
                      className={styles.actionIcon}
                    />
                  </div>
                  <div className={styles.cardContent}>
                    <h3 className={styles.cardTitle}>Meine Tickets</h3>
                    <p className={styles.cardDescription}>
                      Status deiner bisherigen Anfragen prüfen.
                    </p>
                  </div>
                </button>
              </IonCol>

              <IonCol size='12'>
                <button
                  className={`${styles.actionCard} group`}
                  onClick={createTicket}
                >
                  <div className={`${styles.iconWrapper} ${styles.tertiaryBg}`}>
                    <IonIcon
                      icon={createOutline}
                      className={styles.actionIcon}
                    />
                  </div>
                  <div className={styles.cardContent}>
                    <h3 className={styles.cardTitle}>Neues Ticket</h3>
                    <p className={styles.cardDescription}>
                      Ein neues Support-Ticket erstellen.
                    </p>
                  </div>
                </button>
              </IonCol>
            </IonRow>
          </IonGrid>

          {/* Contact CTA Section */}
          {liveChatEnabled && (
            <section className={styles.contactCtaCard}>
              <div className={styles.ctaContent}>
                <h3 className={styles.ctaTitle}>Noch Fragen offen?</h3>
                <p className={styles.ctaDescription}>
                  Unser technisches Support-Team ist rund um die Uhr für dich da.
                </p>
                <IonButton
                  expand='block'
                  className={styles.ctaButton}
                  onClick={openMessaging}
                >
                  Kontakt aufnehmen
                </IonButton>
              </div>
              <div className={styles.decorativeElement1}></div>
              <div className={styles.decorativeElement2}></div>
            </section>
          )}
        </div>
      </IonContent>

    </IonPage>
  )
}

export default Home
